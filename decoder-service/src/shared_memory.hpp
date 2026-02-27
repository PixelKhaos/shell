#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/eventfd.h>

namespace caelestia {

// Ring buffer for frame data in shared memory
// Producer (decoder) writes frames, consumer (Qt) reads them
// Drop-frame friendly: overwrites oldest if consumer lags
class SharedMemoryRingBuffer {
public:
    struct FrameMetadata {
        uint64_t frame_number;
        uint64_t timestamp_us;
        uint32_t width;
        uint32_t height;
        uint32_t stride;
        uint32_t format; // BGRA = 0
        bool valid;
    };

    static constexpr size_t MAX_SLOTS = 6;
    static constexpr uint32_t MAGIC = 0xCAE1E571; // "CAELESTI" in hex-ish

    struct Header {
        uint32_t magic;
        uint32_t version;
        uint32_t slot_count;
        uint32_t slot_size;
        uint64_t write_index;
        uint64_t read_index;
        FrameMetadata frame_slots[MAX_SLOTS];
    };

    SharedMemoryRingBuffer(const std::string& name, size_t frame_size, size_t slot_count = 3);
    ~SharedMemoryRingBuffer();

    // Producer: get next slot to write to
    uint8_t* getWriteSlot(size_t& slot_index);
    void commitWrite(size_t slot_index, const FrameMetadata& metadata);

    // Consumer: get latest available frame
    const uint8_t* getReadSlot(size_t& slot_index, FrameMetadata& metadata);
    void releaseRead(size_t slot_index);

    int getEventFd() const { return event_fd_; }
    const std::string& getName() const { return name_; }

private:
    std::string name_;
    int shm_fd_;
    int event_fd_;
    void* mapped_memory_;
    size_t total_size_;
    Header* header_;
    uint8_t* frame_data_;
    size_t frame_size_;
};

}
