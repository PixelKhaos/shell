#pragma once

#include <string>
#include <functional>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

namespace caelestia {

enum class Command {
    LOAD,
    STOP,
    PAUSE,
    RESUME,
    SET_FPS,
    QUIT
};

struct CommandMessage {
    Command command;
    int slot_id;
    std::string path;
    int fps;
};

class ControlSocket {
public:
    using CommandCallback = std::function<void(const CommandMessage&)>;

    ControlSocket(const std::string& socket_path);
    ~ControlSocket();

    void listen(CommandCallback callback);
    bool processCommands(CommandCallback callback);

private:
    std::string socket_path_;
    int server_fd_;
    int client_fd_;

    CommandMessage parseCommand(const std::string& line);
};

}
