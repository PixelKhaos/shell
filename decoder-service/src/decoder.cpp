#include "decoder.hpp"
#include <iostream>
#include <chrono>
#include <thread>
#include <cstring>

namespace caelestia {

VideoDecoder::VideoDecoder(int slot_id, int target_width, int target_height, int target_fps)
    : slot_id_(slot_id)
    , target_width_(target_width)
    , target_height_(target_height)
    , target_fps_(target_fps)
    , running_(false)
    , paused_(false)
    , should_stop_(false)
    , format_ctx_(nullptr)
    , codec_ctx_(nullptr)
    , hw_device_ctx_(nullptr)
    , frame_(nullptr)
    , sw_frame_(nullptr)
    , sws_ctx_(nullptr)
    , video_stream_idx_(-1)
    , frame_number_(0)
{
}

VideoDecoder::~VideoDecoder() {
    stop();
}

void VideoDecoder::load(const std::string& path) {
    stop();
    
    video_path_ = path;
    should_stop_ = false;
    running_ = true;
    paused_ = false;
    frame_number_ = 0;
    
    decode_thread_ = std::make_unique<std::thread>([this]() {
        try {
            decodeLoop();
        } catch (const std::exception& e) {
            std::cerr << "Decode error in slot " << slot_id_ << ": " << e.what() << std::endl;
        }
        cleanup();
        running_ = false;
    });
    
    std::cout << "Started decoder for slot " << slot_id_ << ": " << video_path_ << std::endl;
}

void VideoDecoder::stop() {
    if (!running_) return;
    
    should_stop_ = true;
    if (decode_thread_ && decode_thread_->joinable()) {
        decode_thread_->join();
    }
    decode_thread_.reset();
    shm_buffer_.reset();
    
    std::cout << "Stopped decoder for slot " << slot_id_ << std::endl;
}

void VideoDecoder::pause() {
    paused_ = true;
}

void VideoDecoder::resume() {
    paused_ = false;
}

void VideoDecoder::setFps(int fps) {
    if (fps == 15 || fps == 30 || fps == 60) {
        target_fps_ = fps;
        std::cout << "Slot " << slot_id_ << " FPS set to " << fps << std::endl;
    }
}

bool VideoDecoder::initHardwareAccel() {
    int ret = av_hwdevice_ctx_create(&hw_device_ctx_, AV_HWDEVICE_TYPE_VAAPI, nullptr, nullptr, 0);
    if (ret < 0) {
        std::cerr << "Failed to create VAAPI device context" << std::endl;
        return false;
    }
    
    codec_ctx_->hw_device_ctx = av_buffer_ref(hw_device_ctx_);
    std::cout << "VAAPI hardware acceleration enabled" << std::endl;
    return true;
}

void VideoDecoder::decodeLoop() {
    format_ctx_ = avformat_alloc_context();
    if (avformat_open_input(&format_ctx_, video_path_.c_str(), nullptr, nullptr) < 0) {
        throw std::runtime_error("Failed to open video file: " + video_path_);
    }
    
    format_ctx_->probesize = 2500000;
    format_ctx_->max_analyze_duration = 500000;
    
    if (avformat_find_stream_info(format_ctx_, nullptr) < 0) {
        throw std::runtime_error("Failed to find stream info");
    }
    
    video_stream_idx_ = -1;
    for (unsigned i = 0; i < format_ctx_->nb_streams; i++) {
        if (format_ctx_->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_idx_ = i;
            break;
        }
    }
    
    if (video_stream_idx_ < 0) {
        throw std::runtime_error("No video stream found");
    }
    
    AVStream* video_stream = format_ctx_->streams[video_stream_idx_];
    
    const AVCodec* codec = avcodec_find_decoder(video_stream->codecpar->codec_id);
    if (!codec) {
        throw std::runtime_error("Codec not found");
    }
    
    codec_ctx_ = avcodec_alloc_context3(codec);
    if (!codec_ctx_) {
        throw std::runtime_error("Failed to allocate codec context");
    }
    
    if (avcodec_parameters_to_context(codec_ctx_, video_stream->codecpar) < 0) {
        throw std::runtime_error("Failed to copy codec parameters");
    }
    
    initHardwareAccel();
    
    if (avcodec_open2(codec_ctx_, codec, nullptr) < 0) {
        throw std::runtime_error("Failed to open codec");
    }
    
    frame_ = av_frame_alloc();
    sw_frame_ = av_frame_alloc();
    
    size_t frame_size = target_width_ * target_height_ * 4; // BGRA
    std::string shm_name = "/caelestia_slot_" + std::to_string(slot_id_);
    shm_buffer_ = std::make_unique<SharedMemoryRingBuffer>(shm_name, frame_size, 3);
    
    // Note: swscaler will be initialized after we know the actual pixel format
    // (which may be NV12 after VAAPI transfer instead of the codec format)
    sws_ctx_ = nullptr;
    
    AVPacket* packet = av_packet_alloc();
    auto frame_duration = std::chrono::microseconds(1000000 / target_fps_);
    auto last_frame_time = std::chrono::steady_clock::now();
    
    // Decode loop
    while (!should_stop_) {
        if (paused_) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            continue;
        }
        
        int ret = av_read_frame(format_ctx_, packet);
        if (ret < 0) {
            av_seek_frame(format_ctx_, video_stream_idx_, 0, AVSEEK_FLAG_BACKWARD);
            continue;
        }
        
        if (packet->stream_index != video_stream_idx_) {
            av_packet_unref(packet);
            continue;
        }
        
        ret = avcodec_send_packet(codec_ctx_, packet);
        av_packet_unref(packet);
        
        if (ret < 0) continue;
        
        while (ret >= 0) {
            ret = avcodec_receive_frame(codec_ctx_, frame_);
            if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
            if (ret < 0) break;
            
            AVFrame* decode_frame = frame_;
            if (frame_->format == AV_PIX_FMT_VAAPI) {
                if (!sw_frame_->data[0]) {
                    sw_frame_->format = AV_PIX_FMT_NV12;
                    sw_frame_->width = frame_->width;
                    sw_frame_->height = frame_->height;
                    if (av_frame_get_buffer(sw_frame_, 0) < 0) {
                        std::cerr << "Failed to allocate sw_frame buffer" << std::endl;
                        continue;
                    }
                }
                
                if (av_hwframe_transfer_data(sw_frame_, frame_, 0) < 0) {
                    std::cerr << "Failed to transfer frame from VAAPI" << std::endl;
                    av_frame_unref(sw_frame_);
                    continue;
                }
                decode_frame = sw_frame_;
            }
            
            if (!sws_ctx_) {
                AVPixelFormat src_fmt = static_cast<AVPixelFormat>(decode_frame->format);
                sws_ctx_ = sws_getContext(
                    decode_frame->width, decode_frame->height, src_fmt,
                    target_width_, target_height_, AV_PIX_FMT_BGRA,
                    SWS_FAST_BILINEAR, nullptr, nullptr, nullptr
                );
                if (!sws_ctx_) {
                    std::cerr << "Failed to create swscaler context" << std::endl;
                    break;
                }
                std::cout << "Initialized swscaler: " << decode_frame->width << "x" << decode_frame->height 
                          << " format=" << src_fmt << " -> " << target_width_ << "x" << target_height_ << " BGRA" << std::endl;
            }
            
            // Rate limiting
            auto now = std::chrono::steady_clock::now();
            auto elapsed = now - last_frame_time;
            if (elapsed < frame_duration) {
                std::this_thread::sleep_for(frame_duration - elapsed);
            }
            last_frame_time = std::chrono::steady_clock::now();
            
            size_t slot_index;
            uint8_t* dst = shm_buffer_->getWriteSlot(slot_index);
            
            // Scale and convert to BGRA
            uint8_t* dst_data[1] = { dst };
            int dst_linesize[1] = { target_width_ * 4 };
            
            sws_scale(sws_ctx_, decode_frame->data, decode_frame->linesize,
                     0, decode_frame->height, dst_data, dst_linesize);
            
            SharedMemoryRingBuffer::FrameMetadata metadata;
            metadata.frame_number = frame_number_++;
            metadata.timestamp_us = av_gettime();
            metadata.width = target_width_;
            metadata.height = target_height_;
            metadata.stride = target_width_ * 4;
            metadata.format = 0; // BGRA
            
            shm_buffer_->commitWrite(slot_index, metadata);
            av_frame_unref(frame_);
        }
    }
    
    av_packet_free(&packet);
    std::cout << "Decode loop exited for slot " << slot_id_ << " (should_stop=" << should_stop_ << ")" << std::endl;
}

void VideoDecoder::cleanup() {
    if (sws_ctx_) {
        sws_freeContext(sws_ctx_);
        sws_ctx_ = nullptr;
    }
    
    if (frame_) {
        av_frame_free(&frame_);
    }
    
    if (sw_frame_) {
        av_frame_free(&sw_frame_);
    }
    
    if (codec_ctx_) {
        avcodec_free_context(&codec_ctx_);
    }
    
    if (format_ctx_) {
        avformat_close_input(&format_ctx_);
    }
    
    if (hw_device_ctx_) {
        av_buffer_unref(&hw_device_ctx_);
    }
}


DecoderService::DecoderService(int target_width, int target_height, int default_fps)
    : target_width_(target_width)
    , target_height_(target_height)
    , default_fps_(default_fps)
{
    std::cout << "Decoder service initialized: " << target_width << "x" << target_height 
              << " @ " << default_fps << " FPS" << std::endl;
}

DecoderService::~DecoderService() {
    for (auto& decoder : decoders_) {
        decoder.reset();
    }
}

void DecoderService::handleCommand(const CommandMessage& msg) {
    if (msg.slot_id < 0 || msg.slot_id >= 2) {
        std::cerr << "Invalid slot ID: " << msg.slot_id << std::endl;
        return;
    }
    
    switch (msg.command) {
    case Command::LOAD:
        if (!decoders_[msg.slot_id]) {
            decoders_[msg.slot_id] = std::make_unique<VideoDecoder>(
                msg.slot_id, target_width_, target_height_, default_fps_
            );
        }
        decoders_[msg.slot_id]->load(msg.path);
        break;
        
    case Command::STOP:
        if (decoders_[msg.slot_id]) {
            decoders_[msg.slot_id]->stop();
        }
        break;
        
    case Command::PAUSE:
        if (decoders_[msg.slot_id]) {
            decoders_[msg.slot_id]->pause();
        }
        break;
        
    case Command::RESUME:
        if (decoders_[msg.slot_id]) {
            decoders_[msg.slot_id]->resume();
        }
        break;
        
    case Command::SET_FPS:
        if (decoders_[msg.slot_id]) {
            decoders_[msg.slot_id]->setFps(msg.fps);
        }
        break;
        
    case Command::QUIT:
        break;
    }
}

VideoDecoder* DecoderService::getDecoder(int slot_id) {
    if (slot_id >= 0 && slot_id < 2) {
        return decoders_[slot_id].get();
    }
    return nullptr;
}

}
