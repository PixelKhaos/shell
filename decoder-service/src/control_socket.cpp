#include "control_socket.hpp"
#include <stdexcept>
#include <iostream>
#include <sstream>
#include <cstring>
#include <poll.h>

namespace caelestia {

ControlSocket::ControlSocket(const std::string& socket_path)
    : socket_path_(socket_path)
    , server_fd_(-1)
    , client_fd_(-1)
{
    server_fd_ = socket(AF_UNIX, SOCK_STREAM | SOCK_NONBLOCK, 0);
    if (server_fd_ < 0) {
        throw std::runtime_error("Failed to create socket");
    }

    unlink(socket_path_.c_str());

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path_.c_str(), sizeof(addr.sun_path) - 1);

    if (bind(server_fd_, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(server_fd_);
        throw std::runtime_error("Failed to bind socket: " + socket_path_);
    }

    if (::listen(server_fd_, 1) < 0) {
        close(server_fd_);
        unlink(socket_path_.c_str());
        throw std::runtime_error("Failed to listen on socket");
    }

    std::cout << "Control socket listening: " << socket_path_ << std::endl;
}

ControlSocket::~ControlSocket() {
    if (client_fd_ >= 0) {
        close(client_fd_);
    }
    if (server_fd_ >= 0) {
        close(server_fd_);
        unlink(socket_path_.c_str());
    }
}

void ControlSocket::listen(CommandCallback callback) {
    while (true) {
        if (!processCommands(callback)) {
            break;
        }
    }
}

bool ControlSocket::processCommands(CommandCallback callback) {
    if (client_fd_ < 0) {
        client_fd_ = accept(server_fd_, nullptr, nullptr);
        if (client_fd_ >= 0) {
            std::cout << "Client connected" << std::endl;
        }
    }

    if (client_fd_ < 0) {
        return true; // No client yet, continue
    }

    struct pollfd pfd;
    pfd.fd = client_fd_;
    pfd.events = POLLIN;
    
    int ret = poll(&pfd, 1, 100);
    if (ret <= 0) {
        return true;
    }

    char buffer[4096];
    ssize_t n = read(client_fd_, buffer, sizeof(buffer) - 1);
    if (n <= 0) {
        std::cout << "Client disconnected" << std::endl;
        close(client_fd_);
        client_fd_ = -1;
        return true;
    }

    buffer[n] = '\0';
    std::string line(buffer);
    std::cout << "Received command: " << line << std::endl;

    try {
        CommandMessage msg = parseCommand(line);
        callback(msg);
        
        if (msg.command == Command::QUIT) {
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Command parse error: " << e.what() << std::endl;
    }

    return true;
}

CommandMessage ControlSocket::parseCommand(const std::string& line) {
    std::istringstream iss(line);
    std::string cmd;
    iss >> cmd;

    CommandMessage msg;
    msg.slot_id = 0;
    msg.fps = 30;

    if (cmd == "LOAD") {
        msg.command = Command::LOAD;
        iss >> msg.slot_id;
        std::getline(iss, msg.path);
        size_t start = msg.path.find_first_not_of(" \t\n\r");
        if (start != std::string::npos) {
            msg.path = msg.path.substr(start);
        }
    } else if (cmd == "STOP") {
        msg.command = Command::STOP;
        iss >> msg.slot_id;
    } else if (cmd == "PAUSE") {
        msg.command = Command::PAUSE;
        iss >> msg.slot_id;
    } else if (cmd == "RESUME") {
        msg.command = Command::RESUME;
        iss >> msg.slot_id;
    } else if (cmd == "SET_FPS") {
        msg.command = Command::SET_FPS;
        iss >> msg.slot_id >> msg.fps;
    } else if (cmd == "QUIT") {
        msg.command = Command::QUIT;
    } else {
        throw std::runtime_error("Unknown command: " + cmd);
    }

    return msg;
}

}
