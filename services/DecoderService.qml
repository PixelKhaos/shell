pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool enabled: Config.background.wallpaper.video.useExternalDecoder
    property bool running: false
    property int targetWidth: 1920
    property int targetHeight: 1080
    property int targetFps: Config.background.wallpaper.video.decoderFps

    readonly property string socketPath: "/tmp/caelestia-decoder.sock"
    readonly property string servicePath: "/usr/local/bin/caelestia-decoder-service"
    
    property var loadCallbacks: ({})

    Component.onCompleted: {
        // Auto-detect resolution from primary screen
        if (Quickshell.screens.length > 0) {
            const screen = Quickshell.screens[0];
            root.targetWidth = screen.width;
            root.targetHeight = screen.height;
        }
        
        if (root.enabled) {
            root.start();
        }
    }

    function start() {
        if (running) return;
        
        decoderProcess.running = true;
        running = true;
        
        const timer = Qt.createQmlObject('import QtQuick; Timer { interval: 800; repeat: false }', root);
        timer.triggered.connect(() => {
            processCommandQueue();
            timer.destroy();
        });
        timer.start();
    }

    function stop() {
        if (!running) return;
        
        sendCommand("QUIT");
        Qt.callLater(() => {
            decoderProcess.running = false;
            running = false;
        });
    }

    function loadVideo(slot, path, onSuccess) {
        if (onSuccess) {
            loadCallbacks[slot] = onSuccess;
        }
        sendCommand("LOAD " + slot + " " + path);
    }

    function stopSlot(slot) {
        if (!running) return;
        sendCommand("STOP " + slot);
    }

    function pauseSlot(slot) {
        if (!running) return;
        sendCommand("PAUSE " + slot);
    }

    function resumeSlot(slot) {
        if (!running) return;
        sendCommand("RESUME " + slot);
    }

    function setFps(slot, fps) {
        if (!running) return;
        sendCommand("SET_FPS " + slot + " " + fps);
    }

    property var commandQueue: []
    property bool sendingCommand: false

    function sendCommand(command) {
        commandQueue.push(command);
        if (running) {
            processCommandQueue();
        }
    }

    function processCommandQueue() {
        if (sendingCommand || commandQueue.length === 0) return;
        
        sendingCommand = true;
        const command = commandQueue.shift();
        
        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        const safeCommand = command.replace(/'/g, "'\"'\"'");
        proc.command = ["sh", "-c", "echo '" + safeCommand + "' | nc -q0 -U '" + root.socketPath + "'"];
        proc.exited.connect(function(code, status) {
            if (code !== 0 && command.startsWith("LOAD")) {
                const retryTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 200; repeat: false }', root);
                retryTimer.triggered.connect(() => {
                    commandQueue.unshift(command);
                    retryTimer.destroy();
                    sendingCommand = false;
                    processCommandQueue();
                });
                retryTimer.start();
            } else {
                if (code === 0 && command.startsWith("LOAD")) {
                    const parts = command.split(" ");
                    const slot = parseInt(parts[1]);
                    if (loadCallbacks[slot]) {
                        Qt.callLater(loadCallbacks[slot]);
                        delete loadCallbacks[slot];
                    }
                }
                
                sendingCommand = false;
                Qt.callLater(processCommandQueue);
            }
            
            proc.destroy();
        });
        proc.running = true;
    }

    Process {
        id: decoderProcess
        command: [
            "sh", "-c",
            root.servicePath + 
            " --width " + root.targetWidth.toString() +
            " --height " + root.targetHeight.toString() +
            " --fps " + root.targetFps.toString() +
            " --socket " + root.socketPath +
            " > /tmp/caelestia-decoder.log 2>&1"
        ]
        
        onExited: (code, status) => {
            console.warn("Decoder service exited with code:", code);
            console.warn("Check /tmp/caelestia-decoder.log for details");
            running = false;
        }
    }

    Component.onDestruction: {
        stop();
    }
}
