pragma Singleton

import QtQuick

QtObject {
    id: root

    function getCategories() {
        return [
            {
                id: "appearance",
                label: "Appearance",
                icon: "palette",
                isDirect: true,
                tabs: ["Wallpaper & Scheme", "Typography & Motion", "Effects"],
                title: "Appearance",
                description: "Customize the look and feel of your desktop",
                children: []
            },
            {
                id: "shell",
                label: "Shell",
                icon: "desktop_windows",
                isDirect: false,
                tabs: [],
                title: "",
                description: "",
                children: [
                    {
                        id: "taskbar",
                        label: "Taskbar",
                        icon: "dock_to_bottom",
                        tabs: ["General", "Workspaces", "Systray & Status"],
                        title: "Taskbar",
                        description: "Configure your taskbar appearance and behavior"
                    },
                    {
                        id: "launcher",
                        label: "Launcher",
                        icon: "apps",
                        tabs: ["General", "Applications", "Actions"],
                        title: "Launcher",
                        description: "Customize application launcher settings"
                    },
                    {
                        id: "dashboard",
                        label: "Dashboard",
                        icon: "dashboard",
                        tabs: ["Dashboard", "Media", "Performance", "Weather"],
                        title: "Dashboard",
                        description: "Configure dashboard widgets and layout"
                    },
                    {
                        id: "sidebar",
                        label: "Sidebar",
                        icon: "side_navigation",
                        tabs: [],
                        title: "Sidebar",
                        description: "Sidebar panel settings"
                    },
                    {
                        id: "utilities",
                        label: "Utilities",
                        icon: "handyman",
                        tabs: [],
                        title: "Utilities",
                        description: "Quick access utilities and tools"
                    },
                    {
                        id: "notifications",
                        label: "Notifications",
                        icon: "notifications",
                        tabs: ["General", "Applications", "On-Screen-Display"],
                        title: "Notifications",
                        description: "Manage notification settings and behavior"
                    },
                    {
                        id: "session",
                        label: "Session",
                        icon: "account_circle",
                        tabs: [],
                        title: "Session Menus",
                        description: "User session and power menu settings"
                    },
                    {
                        id: "lockscreen",
                        label: "Lockscreen",
                        icon: "lock",
                        tabs: [],
                        title: "Lockscreen",
                        description: "Lock screen appearance and security"
                    }
                ]
            },
            {
                id: "display",
                label: "Display",
                icon: "monitor",
                isDirect: true,
                tabs: ["General", "Night Light"],
                title: "Display",
                description: "Monitor configuration and display settings",
                children: []
            },
            {
                id: "services",
                label: "Services",
                icon: "settings_applications",
                isDirect: false,
                tabs: [],
                title: "",
                description: "",
                children: [
                    {
                        id: "network",
                        label: "Network",
                        icon: "wifi",
                        tabs: ["Wireless", "Ethernet", "VPN"],
                        title: "Network",
                        description: "Network connections and settings"
                    },
                    {
                        id: "audio",
                        label: "Audio",
                        icon: "volume_up",
                        tabs: ["Output & Input", "Applications"],
                        title: "Audio",
                        description: "Sound devices and volume control"
                    },
                    {
                        id: "bluetooth",
                        label: "Bluetooth",
                        icon: "bluetooth",
                        tabs: ["Devices", "Settings"],
                        title: "Bluetooth",
                        description: "Bluetooth device management"
                    },
                    {
                        id: "location",
                        label: "Location",
                        icon: "location_on",
                        tabs: [],
                        title: "Location Services",
                        description: "Location access and privacy"
                    },
                    {
                        id: "screenrecorder",
                        label: "Screen Recorder",
                        icon: "screen_record",
                        tabs: [],
                        title: "Screen Recorder",
                        description: "Screen recording settings"
                    }
                ]
            },
            {
                id: "power",
                label: "Power",
                icon: "power_settings_new",
                isDirect: true,
                tabs: ["Power Modes & Inhibit", "Battery Behavior"],
                title: "Power",
                description: "Power management and battery settings",
                children: []
            },
            {
                id: "advanced",
                label: "Advanced",
                icon: "tune",
                isDirect: false,
                tabs: [],
                title: "",
                description: "",
                children: [
                    {
                        id: "plugins",
                        label: "Plugins",
                        icon: "extension",
                        tabs: ["General", "Launcher", "Taskbar", "Dashboard"],
                        title: "Plugins",
                        description: "Manage and configure plugins"
                    },
                    {
                        id: "hooks",
                        label: "Hooks",
                        icon: "link",
                        tabs: [],
                        title: "Hooks",
                        description: "System hooks and automation"
                    }
                ]
            }
        ];
    }

    function getBottomItems() {
        return [
            {
                id: "about",
                label: "About",
                icon: "info",
                isDirect: true,
                tabs: [],
                title: "About Caelestia",
                description: "System information and credits",
                children: []
            },
            {
                id: "updates",
                label: "Updates",
                icon: "update",
                isDirect: true,
                tabs: [],
                title: "Updates",
                description: "System updates and changelog",
                children: []
            }
        ];
    }

    readonly property int count: getCategories().length

    function getByIndex(index) {
        const cats = getCategories();
        if (index >= 0 && index < cats.length)
            return cats[index];
        return null;
    }

    function getById(id) {
        const cats = getCategories();
        for (let i = 0; i < cats.length; i++) {
            if (cats[i].id === id)
                return cats[i];
            const children = cats[i].children;
            for (let j = 0; j < children.length; j++) {
                if (children[j].id === id)
                    return children[j];
            }
        }
        const bottom = getBottomItems();
        for (let i = 0; i < bottom.length; i++) {
            if (bottom[i].id === id)
                return bottom[i];
        }
        return null;
    }

    function getCategoryTabs(id) {
        const cat = getById(id);
        return cat ? cat.tabs : [];
    }

    function isChildActive(parentId, activeId) {
        const parent = getById(parentId);
        if (!parent || parent.isDirect)
            return false;
        for (let i = 0; i < parent.children.length; i++) {
            if (parent.children[i].id === activeId)
                return true;
        }
        return false;
    }
}
