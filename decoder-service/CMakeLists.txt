if(NOT PROJECT_NAME)
    cmake_minimum_required(VERSION 3.20)
    project(caelestia-decoder-service VERSION 1.0.0 LANGUAGES CXX)
    set(CMAKE_CXX_STANDARD 20)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBAV REQUIRED IMPORTED_TARGET
    libavformat
    libavcodec
    libavutil
    libswscale
)
pkg_check_modules(LIBVA REQUIRED IMPORTED_TARGET libva libva-drm)

add_executable(caelestia-decoder-service
    src/main.cpp
    src/decoder.cpp
    src/shared_memory.cpp
    src/control_socket.cpp
)

target_include_directories(caelestia-decoder-service PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(caelestia-decoder-service PRIVATE
    PkgConfig::LIBAV
    PkgConfig::LIBVA
)

if(DEFINED INSTALL_LIBDIR)
    install(TARGETS caelestia-decoder-service
        RUNTIME DESTINATION "${INSTALL_LIBDIR}"
    )
else()
    install(TARGETS caelestia-decoder-service
        RUNTIME DESTINATION bin
    )
endif()
