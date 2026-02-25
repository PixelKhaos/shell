#pragma once

#include <QQuickItem>
#include <QSGTexture>
#include <QSocketNotifier>
#include <QImage>
#include <memory>
#include "sharedmemory_types.hpp"

namespace caelestia {

class VideoFrameItem : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(int slot READ slot WRITE setSlot NOTIFY slotChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    QML_ELEMENT

public:
    explicit VideoFrameItem(QQuickItem* parent = nullptr);
    ~VideoFrameItem() override;

    int slot() const { return slot_id_; }
    void setSlot(int slot);
    Q_INVOKABLE void refresh();  // Reopen shared memory for current slot

    bool ready() const { return ready_; }

signals:
    void slotChanged();
    void readyChanged();
    void frameReady();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;

private slots:
    void onFrameAvailable();

private:
    void tryOpenSharedMemory(int attempt);
    bool openSharedMemory();
    void closeSharedMemory();
    bool readFrame(QImage& image);

    int slot_id_;
    bool ready_;
    
    int shm_fd_;
    int event_fd_;
    void* mapped_memory_;
    size_t mapped_size_;
    SharedMemoryHeader* header_;
    uint8_t* frame_data_;
    
    std::unique_ptr<QSocketNotifier> notifier_;
    QImage current_frame_;
    bool frame_updated_;
    uint64_t last_frame_number_;
};

}
