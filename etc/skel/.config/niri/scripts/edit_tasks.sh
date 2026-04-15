#!/bin/bash
# Script to edit the desktop editable wallpaper with Xournal++
# Designed for Niri and Yoga devices

XOPP_FILE="$HOME/Pictures/task_wallpaper.xopp"
SCRIPTS_DIR="$HOME/.config/niri/scripts"

# Check if watcher is running, if not, start it
if ! pgrep -f "wallpaper_watcher.sh" > /dev/null; then
    "$SCRIPTS_DIR/wallpaper_watcher.sh" &
fi

# Launch Xournal++ (Flatpak)
# We use gio launch to respect desktop environment settings
gio launch /var/lib/flatpak/exports/share/applications/com.github.xournalpp.xournalpp.desktop "$XOPP_FILE"
