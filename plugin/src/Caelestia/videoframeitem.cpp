#include <QTimer>
#include "videoframeitem.hpp"
#include <QSGSimpleTextureNode>
#include <QQuickWindow>
#include <QDebug>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/eventfd.h>
#include <cstring>

namespace caelestia {

VideoFrameItem::VideoFrameItem(QQuickItem* parent)
    : QQuickItem(parent)
    , slot_id_(0)
    , ready_(false)
    , shm_fd_(-1)
    , event_fd_(-1)
    , mapped_memory_(nullptr)
    , mapped_size_(0)
    , header_(nullptr)
    , frame_data_(nullptr)
    , frame_updated_(false)
    , last_frame_number_(0)
{
    setFlag(ItemHasContents, true);
}

VideoFrameItem::~VideoFrameItem() {
    closeSharedMemory();
}

void VideoFrameItem::refresh() {
    if (slot_id_ < 0) return;
    
    closeSharedMemory();
    ready_ = false;
    
    tryOpenSharedMemory(0);
}

void VideoFrameItem::setSlot(int slot) {
    if (slot_id_ == slot) return;
    
    closeSharedMemory();
    slot_id_ = slot;
    ready_ = false;
    
    tryOpenSharedMemory(0);
    emit slotChanged();
}

void VideoFrameItem::tryOpenSharedMemory(int attempt) {
    if (openSharedMemory()) {
        ready_ = true;
        emit readyChanged();
    } else if (attempt < 10) {
        QTimer::singleShot(200, this, [this, attempt]() {
            tryOpenSharedMemory(attempt + 1);
        });
    } else {
        qDebug() << "Failed to open shared memory for slot" << slot_id_ << "after 10 retries";
    }
}

bool VideoFrameItem::openSharedMemory() {
    std::string shm_name = "/caelestia_slot_" + std::to_string(slot_id_);
    
        // Open shared memory
    shm_fd_ = shm_open(shm_name.c_str(), O_RDONLY, 0);
    if (shm_fd_ < 0) {
        return false;
    }
    
    // Get size
    struct stat st;
    if (fstat(shm_fd_, &st) < 0) {
        close(shm_fd_);
        shm_fd_ = -1;
        return false;
    }
    
    mapped_size_ = st.st_size;
    
    mapped_memory_ = mmap(nullptr, mapped_size_, PROT_READ, MAP_SHARED, shm_fd_, 0);
    if (mapped_memory_ == MAP_FAILED) {
        qWarning() << "Failed to mmap shared memory for slot" << slot_id_;
        close(shm_fd_);
        shm_fd_ = -1;
        return false;
    }
    
    header_ = static_cast<SharedMemoryHeader*>(mapped_memory_);
    frame_data_ = static_cast<uint8_t*>(mapped_memory_) + sizeof(SharedMemoryHeader);
    
    if (header_->magic != 0xCAE1E571) {
        qWarning() << "Invalid shared memory magic";
        closeSharedMemory();
        return false;
    }
    
    // Open eventfd for notifications
    // The decoder service creates the eventfd, we need to get it via SCM_RIGHTS
    // For now, we'll poll the shared memory
    // TODO: Implement proper eventfd passing via control socket
    
    poll_timer_ = new QTimer(this);
    connect(poll_timer_, &QTimer::timeout, this, &VideoFrameItem::onFrameAvailable);
    poll_timer_->start(poll_rate_);
    
    return true;
}

void VideoFrameItem::setPollRate(int rate) {
    if (rate == poll_rate_) return;
    poll_rate_ = rate;
    if (poll_timer_ && poll_timer_->isActive()) {
        poll_timer_->setInterval(poll_rate_);
    }
    emit pollRateChanged();
}

void VideoFrameItem::closeSharedMemory() {
    if (poll_timer_) {
        poll_timer_->stop();
    }
    notifier_.reset();
    
    if (event_fd_ >= 0) {
        close(event_fd_);
        event_fd_ = -1;
    }
    
    if (mapped_memory_ != nullptr) {
        munmap(mapped_memory_, mapped_size_);
        mapped_memory_ = nullptr;
        header_ = nullptr;
        frame_data_ = nullptr;
    }
    
    if (shm_fd_ >= 0) {
        close(shm_fd_);
        shm_fd_ = -1;
    }
}

void VideoFrameItem::onFrameAvailable() {
    if (!header_) {
        return;
    }
    
    QImage image;
    if (readFrame(image)) {
        current_frame_ = image;
        frame_updated_ = true;
        update();
        emit frameReady();
    }
}

bool VideoFrameItem::readFrame(QImage& image) {
    if (!header_ || !frame_data_) {
        return false;
    }
    
    // Find most recent valid frame
    for (int i = header_->slot_count - 1; i >= 0; --i) {
        size_t idx = (header_->write_index - 1 - i) % header_->slot_count;
        const auto& metadata = header_->frame_slots[idx];
        
        if (!metadata.valid) {
            continue;
        }
        
        // Skip if we've already processed this frame
        if (metadata.frame_number <= last_frame_number_) {
            return false;
        }
        
        last_frame_number_ = metadata.frame_number;
        
        // Get frame data pointer
        const uint8_t* src = frame_data_ + (idx * header_->slot_size);
        
        // Create QImage wrapping shared memory data (zero-copy)
        // Need to copy because shared memory can be overwritten
        image = QImage(metadata.width, metadata.height, QImage::Format_ARGB32);
        std::memcpy(image.bits(), src, metadata.height * metadata.stride);
        
        return true;
    }
    
    return false;
}

QSGNode* VideoFrameItem::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) {
    Q_UNUSED(data);
    
    if (current_frame_.isNull()) {
        delete oldNode;
        return nullptr;
    }
    
    QSGSimpleTextureNode* node = static_cast<QSGSimpleTextureNode*>(oldNode);
    if (!node) {
        node = new QSGSimpleTextureNode();
    }
    
    if (frame_updated_) {
        QSGTexture* texture = window()->createTextureFromImage(current_frame_);
        node->setTexture(texture);
        node->setOwnsTexture(true);
        frame_updated_ = false;
    }
    
    node->setRect(boundingRect());
    
    return node;
}

}
