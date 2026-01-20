pragma Singleton

import Quickshell
import Quickshell.Io
import qs.config
import Caelestia
import QtQuick

Singleton {
    id: root

    property var history: []
    property var pinnedItems: []
    
    function loadPinnedItems(): void {
        const pinned = Config.launcher.pinnedClipboardItems || [];
        root.pinnedItems = pinned;
    }
    
    function savePinnedItems(): void {
        const configPath = `${Quickshell.env("HOME")}/.config/caelestia/shell.json`;
        const pinnedJson = JSON.stringify(root.pinnedItems);
        
        // update the config file
        const cmd = `jq '.launcher.pinnedClipboardItems = ${pinnedJson}' "${configPath}" > "${configPath}.tmp" && mv "${configPath}.tmp" "${configPath}"`;
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function refresh(): void {
        cliphistProcess.running = true;
    }

    function copyToClipboard(item): void {
        const input = item.id + "\t" + item.content;
        Quickshell.execDetached(["sh", "-c", `echo '${input}' | cliphist decode | wl-copy`]);
        Toaster.toast("Copied to clipboard", item.preview, "content_paste");
    }

    function deleteItem(item): void {
        const input = item.id + "\t" + item.content;
        deleteProcess.command = ["sh", "-c", `echo '${input}' | cliphist delete`];
        deleteProcess.running = true;
    }

    function togglePin(item): void {
        const index = root.pinnedItems.indexOf(item.id);
        if (index !== -1) {
            root.pinnedItems.splice(index, 1);
        } else {
            root.pinnedItems.push(item.id);
        }
        savePinnedItems();
        root.refresh();
    }

    Process {
        id: cliphistProcess
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const lines = text.trim().split('\n');
                    root.history = lines.map((line, index) => {
                        const parts = line.split('\t');
                        const id = parts[0] || "";
                        const content = parts.slice(1).join('\t') || line;
                        
                        return {
                            id: id,
                            content: content,
                            preview: content.substring(0, 100),
                            isPinned: root.pinnedItems.includes(id),
                            index: index
                        };
                    });
                }
            }
        }
    }

    Process {
        id: deleteProcess
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Component.onCompleted: {
        loadPinnedItems();
        refresh();
    }
}
