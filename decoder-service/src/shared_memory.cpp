#include "shared_memory.hpp"
#include <stdexcept>
#include <cstring>
#include <iostream>

namespace caelestia {

SharedMemoryRingBuffer::SharedMemoryRingBuffer(const std::string& name, size_t frame_size, size_t slot_count)
    : name_(name)
    , shm_fd_(-1)
    , event_fd_(-1)
    , mapped_memory_(nullptr)
    , frame_size_(frame_size)
{
    if (slot_count > MAX_SLOTS) {
        throw std::runtime_error("Slot count exceeds maximum");
    }

    shm_fd_ = shm_open(name_.c_str(), O_CREAT | O_RDWR, 0600);
    if (shm_fd_ < 0) {
        throw std::runtime_error("Failed to create shared memory: " + name_);
    }

    total_size_ = sizeof(Header) + (frame_size_ * slot_count);
    if (ftruncate(shm_fd_, total_size_) < 0) {
        close(shm_fd_);
        shm_unlink(name_.c_str());
        throw std::runtime_error("Failed to resize shared memory");
    }

    mapped_memory_ = mmap(nullptr, total_size_, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd_, 0);
    if (mapped_memory_ == MAP_FAILED) {
        close(shm_fd_);
        shm_unlink(name_.c_str());
        throw std::runtime_error("Failed to map shared memory");
    }

    header_ = static_cast<Header*>(mapped_memory_);
    header_->magic = MAGIC;
    header_->version = 1;
    header_->slot_count = slot_count;
    header_->slot_size = frame_size_;
    header_->write_index = 0;
    header_->read_index = 0;

    for (size_t i = 0; i < MAX_SLOTS; ++i) {
        header_->frame_slots[i].valid = false;
    }

    frame_data_ = static_cast<uint8_t*>(mapped_memory_) + sizeof(Header);

    // Create eventfd for frame notifications
    event_fd_ = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (event_fd_ < 0) {
        munmap(mapped_memory_, total_size_);
        close(shm_fd_);
        shm_unlink(name_.c_str());
        throw std::runtime_error("Failed to create eventfd");
    }

    std::cout << "Created shared memory: " << name_ << " (" << total_size_ << " bytes, " 
              << slot_count << " slots)" << std::endl;
}

SharedMemoryRingBuffer::~SharedMemoryRingBuffer() {
    if (event_fd_ >= 0) {
        close(event_fd_);
    }
    if (mapped_memory_ != nullptr) {
        munmap(mapped_memory_, total_size_);
    }
    if (shm_fd_ >= 0) {
        close(shm_fd_);
        shm_unlink(name_.c_str());
    }
}

uint8_t* SharedMemoryRingBuffer::getWriteSlot(size_t& slot_index) {
    slot_index = header_->write_index % header_->slot_count;
    return frame_data_ + (slot_index * frame_size_);
}

void SharedMemoryRingBuffer::commitWrite(size_t slot_index, const FrameMetadata& metadata) {
    header_->frame_slots[slot_index] = metadata;
    // ensure frame data is written before valid flag
    __sync_synchronize();
    header_->frame_slots[slot_index].valid = true;
    header_->write_index++;
}

const uint8_t* SharedMemoryRingBuffer::getReadSlot(size_t& slot_index, FrameMetadata& metadata) {
    // Find most recent valid frame
    for (int i = header_->slot_count - 1; i >= 0; --i) {
        size_t idx = (header_->write_index - 1 - i) % header_->slot_count;
        if (header_->frame_slots[idx].valid) {
            slot_index = idx;
            metadata = header_->frame_slots[idx];
            return frame_data_ + (idx * frame_size_);
        }
    }
    return nullptr;
}

void SharedMemoryRingBuffer::releaseRead(size_t slot_index) {

}

}
