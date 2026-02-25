#pragma once

#include <cstdint>

namespace caelestia {

struct FrameMetadata {
    uint64_t frame_number;
    uint64_t timestamp_us;
    uint32_t width;
    uint32_t height;
    uint32_t stride;
    uint32_t format;
    bool valid;
};

struct SharedMemoryHeader {
    uint32_t magic;
    uint32_t version;
    uint32_t slot_count;
    uint32_t slot_size;
    uint64_t write_index;
    uint64_t read_index;
    FrameMetadata frame_slots[6];
};

}
