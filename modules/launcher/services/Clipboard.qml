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

    property string pendingImageUrl: ""
    property string pendingImageMime: ""

    function copyImageFromUrl(url): void {
        if (copyImageProcess.running) {
            return;
        }

        const escapedUrl = url.replace(/'/g, "'\\''");
        let mimeType = "image/png";
        if (url.match(/\.jpe?g$/i))
            mimeType = "image/jpeg";
        else if (url.match(/\.png$/i))
            mimeType = "image/png";
        else if (url.match(/\.gif$/i))
            mimeType = "image/gif";
        else if (url.match(/\.webp$/i))
            mimeType = "image/webp";

        root.pendingImageUrl = escapedUrl;
        root.pendingImageMime = mimeType;

        const cmd = `curl -sL '${escapedUrl}' | wl-copy --type '${mimeType}'`;
        copyImageProcess.command = ["sh", "-c", cmd];
        copyImageProcess.running = true;
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

    function clearAll(category): void {
        let itemsToDelete = root.history.filter(item => {
            if (item.isPinned)
                return false; // Never delete pinned items

            if (category === "images") {
                return item.isImage;
            } else if (category === "misc") {
                return !item.isImage;
            }
            return true;
        });

        if (itemsToDelete.length === 0) {
            Toaster.toast("Nothing to clear", "No non-pinned items in this category", "info");
            return;
        }

        // Build a shell script that deletes each item
        const deleteCommands = itemsToDelete.map(item => {
            const escapedId = item.id.replace(/'/g, "'\\''");
            return `printf '%s' '${escapedId}' | cliphist delete`;
        }).join('; ');

        deleteProcess.command = ["sh", "-c", deleteCommands];
        deleteProcess.running = true;

        const categoryName = category === "all" ? "All" : category === "images" ? "Images" : "Misc";
        const count = itemsToDelete.length;
        Toaster.toast("Clipboard cleared", `${count} ${categoryName.toLowerCase()} item${count !== 1 ? 's' : ''} deleted (pinned items preserved)`, "delete_sweep");
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

                        const isImage = content.includes("[[ binary data");

                        // Detect potential HTML images (content is truncated in list, so just check for <img tag)
                        // We'll extract the actual URL later when needed
                        const hasHtmlImage = !isImage && content.includes("<img");

                        const isDirectImageUrl = !isImage && !hasHtmlImage && content.match(/^https?:\/\/.*\.(png|jpg|jpeg|gif|webp|bmp)/i);

                        return {
                            id: id,
                            content: content,
                            preview: content.substring(0, 100),
                            isPinned: root.pinnedItems.includes(id),
                            isImage: isImage,
                            imageUrl: isDirectImageUrl ? content.trim() : "",
                            hasImageUrl: hasHtmlImage || isDirectImageUrl,
                            needsDecodeForUrl: hasHtmlImage,
                            index: index
                        };
                    });
                }
            }
        }
    }

    Process {
        id: copyImageProcess
        stdout: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Toaster.toast("Image copied", "Downloaded and copied image to clipboard", "image");
                Qt.callLater(() => root.refresh());
            } else {
                Toaster.toast("Copy failed", "Failed to download or copy image", "error");
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
