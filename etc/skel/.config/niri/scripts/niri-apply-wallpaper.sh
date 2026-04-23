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

# Generiamo un nome di file univoco per bypassare la cache di DMS
WALLPAPER_FINAL="$HOME/Pictures/task_wallpaper_rendered_$(date +%s).png"

# Perform rotation (host-native ImageMagick conversion)
if [ "$ROTATE" = "0" ]; then
    cp -f "$WALLPAPER_BASE" "${WALLPAPER_FILE}.tmp"
else
    # Distrobox host exec might be needed depending on the system, but since niri spawned this:
    convert "$WALLPAPER_BASE" -rotate "$ROTATE" -define png:color-type=6 "${WALLPAPER_FILE}.tmp"
fi

# Puliamo i vecchi sfondi renderizzati per evitare di accumularli
rm -f "$HOME/Pictures/task_wallpaper_rendered_"*.png

# Rinominiamo il temporaneo col nuovo nome univoco
mv -f "${WALLPAPER_FILE}.tmp" "$WALLPAPER_FINAL"

# Apply wallpaper using DankMaterialShell
dms ipc call wallpaper set "$WALLPAPER_FINAL"
