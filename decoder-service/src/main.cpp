#include "decoder.hpp"
#include "control_socket.hpp"
#include <iostream>
#include <csignal>
#include <atomic>
#include <cstdlib>

extern "C" {
#include <libavformat/avformat.h>
}

namespace {
std::atomic<bool> g_running{true};

void signalHandler(int signal) {
    std::cout << "\nReceived signal " << signal << ", shutting down..." << std::endl;
    g_running = false;
}
}

int main(int argc, char* argv[]) {
    int width = 1920;
    int height = 1080;
    int fps = 30;
    std::string socket_path = "/tmp/caelestia-decoder.sock";
    
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "--width" && i + 1 < argc) {
            width = std::atoi(argv[++i]);
        } else if (arg == "--height" && i + 1 < argc) {
            height = std::atoi(argv[++i]);
        } else if (arg == "--fps" && i + 1 < argc) {
            fps = std::atoi(argv[++i]);
        } else if (arg == "--socket" && i + 1 < argc) {
            socket_path = argv[++i];
        } else if (arg == "--help") {
            std::cout << "Usage: " << argv[0] << " [options]\n"
                      << "Options:\n"
                      << "  --width <pixels>    Target width (default: 1920)\n"
                      << "  --height <pixels>   Target height (default: 1080)\n"
                      << "  --fps <fps>         Default FPS (15/30/60, default: 30)\n"
                      << "  --socket <path>     Control socket path (default: /tmp/caelestia-decoder.sock)\n"
                      << "  --help              Show this help\n";
            return 0;
        }
    }
    
    if (fps != 15 && fps != 30 && fps != 60) {
        std::cerr << "Invalid FPS value. Must be 15, 30, or 60." << std::endl;
        return 1;
    }
    
    std::cout << "Caelestia Decoder Service\n"
              << "Target resolution: " << width << "x" << height << "\n"
              << "Default FPS: " << fps << "\n"
              << "Control socket: " << socket_path << std::endl;
    
    std::signal(SIGINT, signalHandler);
    std::signal(SIGTERM, signalHandler);
    
    try {
        av_log_set_level(AV_LOG_WARNING);
        
        caelestia::DecoderService service(width, height, fps);
        
        caelestia::ControlSocket control(socket_path);
        
        std::cout << "Service ready, waiting for commands..." << std::endl;
        
        // Main loop
        while (g_running) {
            bool continue_running = control.processCommands([&service](const caelestia::CommandMessage& msg) {
                if (msg.command == caelestia::Command::QUIT) {
                    g_running = false;
                    return;
                }
                service.handleCommand(msg);
            });
            
            if (!continue_running) {
                break;
            }
            
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        
        std::cout << "Shutting down..." << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
