#pragma once

#include "shared_memory.hpp"
#include "control_socket.hpp"
#include <string>
#include <memory>
#include <atomic>
#include <thread>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/hwcontext.h>
#include <libavutil/hwcontext_vaapi.h>
#include <libavutil/time.h>
#include <libswscale/swscale.h>
}

namespace caelestia {

class VideoDecoder {
public:
    VideoDecoder(int slot_id, int target_width, int target_height, int target_fps);
    ~VideoDecoder();

    void load(const std::string& path);
    void stop();
    void pause();
    void resume();
    void setFps(int fps);

    bool isRunning() const { return running_; }
    bool isPaused() const { return paused_; }

private:
    void decodeLoop();
    bool initHardwareAccel();
    void cleanup();
    
    int slot_id_;
    int target_width_;
    int target_height_;
    int target_fps_;
    
    std::atomic<bool> running_;
    std::atomic<bool> paused_;
    std::atomic<bool> should_stop_;
    
    std::string video_path_;
    
    std::unique_ptr<std::thread> decode_thread_;
    std::unique_ptr<SharedMemoryRingBuffer> shm_buffer_;
    
    // FFmpeg contexts
    AVFormatContext* format_ctx_;
    AVCodecContext* codec_ctx_;
    AVBufferRef* hw_device_ctx_;
    AVFrame* frame_;
    AVFrame* sw_frame_;
    SwsContext* sws_ctx_;
    
    int video_stream_idx_;
    uint64_t frame_number_;
};

class DecoderService {
public:
    DecoderService(int target_width, int target_height, int default_fps);
    ~DecoderService();

    void handleCommand(const CommandMessage& msg);
    VideoDecoder* getDecoder(int slot_id);

private:
    int target_width_;
    int target_height_;
    int default_fps_;
    
    std::unique_ptr<VideoDecoder> decoders_[2]; // Slot A and B
};

}
