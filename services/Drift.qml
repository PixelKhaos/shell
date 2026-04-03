pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    property string kbLayout: "??"
    property string kbLayoutFull: "Unknown"
    
    property bool capsLock: false
    property bool numLock: false
    
    // Future: Window/Workspace properties
    // property var windows: []
    // property var workspaces: []
        
    property bool _hadLayout: false
    property var _layoutCodes: ["us"]
    
    Component.onCompleted: {
        // Read config first, then initial state
        _readConfig.running = true;
    }
        
    function _handleIpcEvent(eventJson) {
        try {
            const event = JSON.parse(eventJson);
            
            // Route to appropriate handler based on event type
            switch (event.event) {
                case "layout_changed":
                    _handleLayoutChanged(event);
                    break;
                // Future event types:
                // case "caps_lock_changed":
                // case "window_opened":
                // case "window_focused":
                // case "frame_added":
                // case "frame_changed":

                default:
                    console.log("Drift: Unknown event type:", event.event);
            }
        } catch (e) {
            console.warn("Drift: Failed to parse IPC event:", e);
        }
    }
    
    function _handleLayoutChanged(event) {
        const layoutName = event.layout;
        const code = _extractLayoutCode(layoutName);
        
        root.kbLayout = code;
        root.kbLayoutFull = layoutName;
        _hadLayout = true;
    }
        
    function _parseInitialState(content) {
        const lines = content.split('\n');
        
        for (const line of lines) {
            if (line.startsWith("layout=")) {
                const layoutName = line.substring(7).trim();
                const code = _extractLayoutCode(layoutName);
                root.kbLayout = code;
                root.kbLayoutFull = layoutName;
                _hadLayout = true;
                break;
            }
            // Future: Parse other state fields
            // if (line.startsWith("x=")) { ... }
            // if (line.startsWith("zoom=")) { ... }
        }
    }
        
    function _extractLayoutCode(layoutName) {
        const lower = layoutName.toLowerCase();
        
        for (const configCode of root._layoutCodes) {
            const codeLower = configCode.toLowerCase();
            
            if (lower.startsWith(codeLower)) {
                return configCode.toUpperCase();
            }
            
            if (lower.includes("(" + codeLower + ")")) {
                return configCode.toUpperCase();
            }
            
            if ((codeLower === "se" && lower.startsWith("swed")) ||
                (codeLower === "us" && lower.startsWith("engl")) ||
                (codeLower === "gb" && lower.startsWith("engl") && lower.includes("uk")) ||
                (codeLower === "de" && lower.startsWith("germ")) ||
                (codeLower === "fr" && lower.startsWith("fren")) ||
                (codeLower === "no" && lower.startsWith("norw")) ||
                (codeLower === "dk" && lower.startsWith("dan")) ||
                (codeLower === "fi" && lower.startsWith("finn"))) {
                return configCode.toUpperCase();
            }
        }
        
        return layoutName.substring(0, 2).toUpperCase();
    }
        
    Process {
        id: _readConfig
        command: ["sh", "-c", "grep -E '^\\s*layout\\s*=' \"$XDG_CONFIG_HOME/driftwm/config.toml\" 2>/dev/null || grep -E '^\\s*layout\\s*=' ~/.config/driftwm/config.toml 2>/dev/null || echo ''"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/layout\s*=\s*"([^"]+)"/);
                if (match) {
                    root._layoutCodes = match[1].split(',').map(l => l.trim());
                }
                
                // Now that we have layout codes, read initial state and start IPC
                _readInitialState.running = true;
                _ipcSocket.running = true;
            }
        }
    }
    
    Process {
        id: _readInitialState
        command: ["sh", "-c", "cat \"$XDG_RUNTIME_DIR/driftwm/state\" 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: root._parseInitialState(text)
        }
    }
    
    Process {
        id: _ipcSocket
        command: ["sh", "-c", "nc -U \"$XDG_RUNTIME_DIR/driftwm/events.sock\" 2>/dev/null || sleep infinity"]
        
        running: false
        
        stdout: SplitParser {
            onRead: line => {
                root._handleIpcEvent(line.trim());
            }
        }
    }
}
