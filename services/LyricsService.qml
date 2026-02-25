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
    property string backend: "Local"
    property var currentSongId: 0

    property real offset

    readonly property string lyricsDir: Paths.absolutePath(Config.paths.lyricsDir)
    readonly property string lyricsMapFile: Paths.absolutePath(Config.paths.lyricsDir) + "/lyrics_map.json"

    property int currentRequestId: 0

    // The data source for the UI
    readonly property alias model: lyricsModel
    readonly property alias candidatesModel: fetchedCandidatesModel

    property var lyricsMap: ({})

    ListModel { id: lyricsModel }
    ListModel { id: fetchedCandidatesModel }

    Timer {
        id: seekTimer
        interval: 500
        onTriggered: root.isManualSeeking = false
    }

    Timer {
        id: fallbackTimer
        interval: 200
        onTriggered: {
            if (lyricsModel.count === 0) {
                root.backend = "NetEase"
                fallbackToOnline();
            }
        }
    }

    Timer {
        id: loadDebounce
        interval: 50
        onTriggered: root._doLoadLyrics()
    }

    FileView {
        id: lyricsMapFileView
        path: root.lyricsMapFile
        onLoaded: {
            try {
                root.lyricsMap = JSON.parse(text());
            } catch(e) {
                root.lyricsMap = {};
            }
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
                root.backend = "NetEase"
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
        function onMetadataChanged() {
            loadLyrics();
        }
    }

    Process {
        id: saveLyricsMap
        command: ["sh", "-c", `echo '${JSON.stringify(root.lyricsMap)}' > "${root.lyricsMapFile}"`]
    }

    function savePrefs() {
        let meta = getMetadata();
        if (!meta) return;
        let key = `${meta.artist} - ${meta.title}`;
        let existing = root.lyricsMap[key] ?? {};
        console.log(root.offset)
        root.lyricsMap[key] = {
            offset: root.offset,
            backend: root.backend,
            neteaseId: existing.neteaseId ?? null
        };
        root.lyricsMap = root.lyricsMap;
        saveLyricsMap.command = ["sh", "-c", `echo '${JSON.stringify(root.lyricsMap).replace(/'/g, "'\\''")}' > "${root.lyricsMapFile}"`];
        saveLyricsMap.running = true;
    }

    function getMetadata() {
        if (!player || !player.metadata) return null;
        let artist = player.metadata["xesam:artist"];
        let title = player.metadata["xesam:title"];
        if (Array.isArray(artist)) artist = artist.join(", ");
        return { artist: artist || "Unknown", title: title || "Unknown" };
    }
    
    function loadLyrics() {
        loadDebounce.restart()
    }

    function _doLoadLyrics() {
        let meta = getMetadata();
        if (!meta) return;

        loading = true;
        lyricsModel.clear();
        currentIndex = -1;
        root.currentSongId = 0
        root.backend = "Local"

        root.currentRequestId++;
        let requestId = root.currentRequestId;

        let key = `${meta.artist} - ${meta.title}`;
        let saved = root.lyricsMap[key];
        root.offset = saved?.offset ?? 0.0;

        if (saved?.neteaseId && saved?.backend == "NetEase") {
            root.backend = "NetEase";
            root.currentSongId = saved.neteaseId
            fetchNetEaseLyrics(saved.neteaseId, meta.title, meta.artist, requestId);
            fetchNetEaseCandidates(meta.title, meta.artist, requestId)
            return;
        }
        
        if (saved?.backend == "NetEase") {
            fallbackTimer.restart();
            return;
        } 

        let filename = `${meta.artist} - ${meta.title}.lrc`;
        let cleanDir = lyricsDir.replace(/\/$/, "");
        let fullPath = cleanDir + "/" + filename;

        lrcFile.path = "";
        lrcFile.path = fullPath;
        
        if (saved?.backend == "Local") return
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

    function fetchNetEaseCandidates(title, artist, reqId) {
        Requests.resetCookies();
        const query = encodeURIComponent(title + " " + artist);
        const url = `https://music.163.com/api/search/get?s=${query}&type=1&limit=5`;
        Requests.get(url, text => {
            if (reqId !== root.currentRequestId) return;
            const res = JSON.parse(text);
            const songs = res.result?.songs || [];
            
            // Populate candidates model
            fetchedCandidatesModel.clear();
            for (let s of songs) {
                fetchedCandidatesModel.append({
                    id: s.id,
                    title: s.name || "Unknown Title",
                    artist: s.artists?.map(a => a.name).join(", ") || "Unknown Artist"
                });
            }
        },
        err => {},
        {
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0",
            "Referer": "https://music.163.com/"
        });

    }

    function fetchNetEase(title, artist, reqId) {
        Requests.resetCookies();
        const query = encodeURIComponent(title + " " + artist);
        const url = `https://music.163.com/api/search/get?s=${query}&type=1&limit=5`;
        Requests.get(url, text => {
            if (reqId !== root.currentRequestId) return;
            const res = JSON.parse(text);
            const songs = res.result?.songs || [];
            
            // Populate candidates model
            fetchedCandidatesModel.clear();
            for (let s of songs) {
                fetchedCandidatesModel.append({
                    id: s.id,
                    title: s.name || "Unknown Title",
                    artist: s.artists?.map(a => a.name).join(", ") || "Unknown Artist"
                });
            }

            const bestMatch = songs.find(s => {
                const inputArtist = String(artist || "").toLowerCase();
                const sArtist = String(s.artists?.[0]?.name || "").toLowerCase();
                return inputArtist.includes(sArtist) || sArtist.includes(inputArtist);
            });

            if (bestMatch) {
                let key = `${artist} - ${title}`;
                let existing = root.lyricsMap[key] ?? {};
                root.lyricsMap[key] = { offset: (root.lyricsMap[key]?.offset ?? 0.0), neteaseId: bestMatch.id };
                savePrefs();
                root.currentSongId = bestMatch.id;
                fetchNetEaseLyrics(bestMatch.id, title, artist, reqId);
            } else {
                console.log("NetEase: No reliable match found");
            }
        }, err => {
            console.log("netease error:", err);
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
                console.log("No lyrics!")
            }
        });
    }

    function selectCandidate(songId) {
        let meta = getMetadata();
        if (!meta) return;
        let key = `${meta.artist} - ${meta.title}`;
        let existing = root.lyricsMap[key] ?? {};
        root.lyricsMap[key] = { offset: (root.lyricsMap[key]?.offset ?? 0.0), neteaseId: songId };
        root.backend = "NetEase"
        root.currentSongId = songId
        savePrefs();
        fetchNetEaseLyrics(songId, meta.title, meta.artist, currentRequestId);
    }

    function updatePosition() {
        if (isManualSeeking || !player || lyricsModel.count === 0) return;

        let pos = player.position - root.offset;
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
            player.position = time + root.offset + 0.01; // for the rounding
        }

        seekTimer.restart();
    }
}
