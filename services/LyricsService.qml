pragma Singleton

import qs.config
import qs.utils
import Caelestia
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../utils/scripts/lrcparser.js" as Lrc

Singleton {
    id: root

    property var player: Players.active
    property int currentIndex: -1
    property bool loading: false
    property bool isManualSeeking: false
    property bool lyricsVisible: true

    readonly property string lyricsDir: Paths.absolutePath(Config.paths.lyricsDir)

    property int currentRequestId: 0

    // The data source for the UI
    readonly property alias model: lyricsModel

    ListModel { id: lyricsModel }

    Timer {
        id: seekTimer
        interval: 500
        onTriggered: root.isManualSeeking = false
    }

    Timer {
        id: fallbackTimer
        interval: 200
        onTriggered: {
            if (lyricsModel.count === 0) fallbackToOnline();
        }
    }

    FileView {
        id: lrcFile
        onLoaded: {
            fallbackTimer.stop();
            let parsed = Lrc.parseLrc(text());
            if (parsed.length > 0) {
                updateModel(parsed);
                loading = false;
            } else {
                fallbackToOnline();
            }
        }
    }

    Connections {
        target: Players
        function onActiveChanged() {
            root.player = Players.active;
            loadLyrics();
        }
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onMetadataChanged() { loadLyrics(); }
    }

    function getMetadata() {
        if (!player || !player.metadata) return null;
        let artist = player.metadata["xesam:artist"];
        let title = player.metadata["xesam:title"];
        if (Array.isArray(artist)) artist = artist.join(", ");
        return { artist: artist || "Unknown", title: title || "Unknown" };
    }

    function loadLyrics() {
        let meta = getMetadata();
        if (!meta) return;

        loading = true;
        lyricsModel.clear();
        currentIndex = -1;

        root.currentRequestId++;
        let requestId = root.currentRequestId;

        let filename = `${meta.artist} - ${meta.title}.lrc`;
        let cleanDir = lyricsDir.replace(/\/$/, "");
        let fullPath = cleanDir + "/" + filename;

        lrcFile.path = "";
        lrcFile.path = fullPath;

        // Fallback safety: If FileView doesn't trigger onLoaded (file missing),
        fallbackTimer.restart();
    }

    function updateModel(parsedArray) {
        lyricsModel.clear();
        for (let line of parsedArray) {
            lyricsModel.append({ time: line.time, text: line.text });
        }
    }

    function fallbackToOnline() {
        let meta = getMetadata();
        if (!meta) return;
        fetchNetEase(meta.title, meta.artist, root.currentRequestId);
    }

    function fetchNetEase(title, artist, reqId) {
        Requests.resetCookies();
        const query = encodeURIComponent(title + " " + artist);
        const url = `https://music.163.com/api/search/get?s=${query}&type=1&limit=5`;
        Requests.get(url, text => {
            if (reqId !== root.currentRequestId) return;
            const res = JSON.parse(text);
            const songs = res.result?.songs || [];

            const bestMatch = songs.find(s => {
                const inputArtist = String(artist || "").toLowerCase();
                const sArtist = String(s.artists?.[0]?.name || "").toLowerCase();
                return inputArtist.includes(sArtist) || sArtist.includes(inputArtist);
            });

            if (bestMatch) {
                fetchNetEaseLyrics(bestMatch.id, title, artist, reqId);
            } else {
                console.log("NetEase: No reliable match found, trying lrclib...");
                fetchLRCLIB(title, artist, reqId);
            }
        }, err => {
            console.log("netease error:", err);
            fetchLRCLIB(title, artist, reqId);
        }, {
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0",
            "Referer": "https://music.163.com/"
        });
    }

    function fetchNetEaseLyrics(id, title, artist, reqId) {
        const url = `https://music.163.com/api/song/lyric?id=${id}&lv=1&kv=1&tv=-1`;
        Requests.get(url, text => {
            if (reqId !== root.currentRequestId) return;
            const res = JSON.parse(text);
            if (res.lrc?.lyric) {
                updateModel(Lrc.parseLrc(res.lrc.lyric));
                loading = false;
            } else {
                fetchLRCLIB(title, artist, reqId);
            }
        }, () => {
            fetchLRCLIB(title, artist, reqId);
        });
    }

    function fetchLRCLIB(title, artist, reqId) {
        const url = `https://lrclib.net/api/get?artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}&_=${Date.now()}`;

        Requests.get(url, text => {
            if (reqId !== root.currentRequestId) return;
            const res = JSON.parse(text);
            if (res.syncedLyrics) {
                updateModel(Lrc.parseLrc(res.syncedLyrics));
                loading = false;
                return;
            }
            fetchLRCLIBSearch(title, artist, reqId);
        }, err => {
            console.log("lrclib error:", err);
            fetchLRCLIBSearch(title, artist, reqId);
        });
    }

    function fetchLRCLIBSearch(title, artist, reqId) {
        const url = `https://lrclib.net/api/search?q=${encodeURIComponent(title + " " + artist)}&_=${Date.now()}`;

        Requests.get(url, text => {
            if (reqId !== root.currentRequestId) return;
            const results = JSON.parse(text);
            const best = results.find(r => r.syncedLyrics);
            if (best) {
                updateModel(Lrc.parseLrc(best.syncedLyrics));
                loading = false;
                return;
            }
            loading = false;
            console.log("No lyrics found anywhere.");
        }, err => {
            console.log("lrclib search error:", err);
            loading = false;
        });
    }

    function updatePosition() {
        if (isManualSeeking || !player || lyricsModel.count === 0) return;

        let pos = player.position;
        let newIdx = -1;
        for (let i = lyricsModel.count - 1; i >= 0; i--) {
            if (pos >= lyricsModel.get(i).time - 0.1) { // 100ms fudge factor
                newIdx = i;
                break;
            }
        }

        if (newIdx !== currentIndex) {
            root.currentIndex = newIdx;
        }
    }

    function jumpTo(index, time) {
        root.isManualSeeking = true;
        root.currentIndex = index;

        if (player) {
            player.position = time + 0.01; // for the rounding
        }

        seekTimer.restart();
    }
}
