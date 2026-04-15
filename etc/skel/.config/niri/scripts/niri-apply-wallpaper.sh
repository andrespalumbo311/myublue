#!/bin/bash
# Apply counter-rotation to the base wallpaper using swaybg
# Designed for Niri on Yoga devices.

WALLPAPER_BASE="$HOME/Pictures/task_wallpaper_base.png"
WALLPAPER_FILE="$HOME/Pictures/task_wallpaper.png"

# Wait for base image if missing
if [ ! -f "$WALLPAPER_BASE" ]; then
    echo "Base wallpaper missing: $WALLPAPER_BASE"
    exit 1
fi

# Parse current transform from niri
TRANSFORM=$(niri msg -j outputs | jq -r '."eDP-1".logical.transform')

case "$TRANSFORM" in
    "90")  ROTATE="90" ;;   
    "180") ROTATE="180" ;;
    "270") ROTATE="-90" ;;  
    *)     ROTATE="0" ;;
esac

# Perform rotation (host-native ImageMagick conversion)
if [ "$ROTATE" = "0" ]; then
    cp -f "$WALLPAPER_BASE" "${WALLPAPER_FILE}.tmp"
else
    # Distrobox host exec might be needed depending on the system, but since niri spawned this:
    convert "$WALLPAPER_BASE" -rotate "$ROTATE" -define png:color-type=6 "${WALLPAPER_FILE}.tmp"
fi
mv -f "${WALLPAPER_FILE}.tmp" "$WALLPAPER_FILE"

# Manage Swaybg lifecycle globally without race conditions
FALLBACK_PID=$(pgrep -f 'swaybg -c #20B2AA' | head -n 1)
if [ -z "$FALLBACK_PID" ]; then
    swaybg -c "#20B2AA" &
    FALLBACK_PID=$!
fi

swaybg -i "$WALLPAPER_FILE" -m fill &
NEW_PID=$!

sleep 0.5

if kill -0 $NEW_PID 2>/dev/null; then
    for pid in $(pgrep swaybg); do
        if [ "$pid" != "$NEW_PID" ] && [ "$pid" != "$FALLBACK_PID" ]; then
            kill -9 "$pid"
        fi
    done
fi
