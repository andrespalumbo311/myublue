#!/bin/bash
# Usiamo l'immagine trovata in Pictures
WALLPAPER="$HOME/Pictures/task_wallpaper.png"

# Se l'immagine non esiste, ripieghiamo su un colore chiaro
if [ ! -f "$WALLPAPER" ]; then
    BG_OPTS="--color f0f2f5"
else
    BG_OPTS="--image $WALLPAPER --scaling fill"
fi

swaylock \
    $BG_OPTS \
    --ring-color 7fc8ff \
    --inside-color ffffff88 \
    --text-color 333333 \
    --key-hl-color 007aff \
    --bs-hl-color ff3b30 \
    --ring-ver-color 7fc8ff \
    --inside-ver-color ffffff \
    --ring-wrong-color ff3b30 \
    --inside-wrong-color ffffff \
    --ring-clear-color d1eaff \
    --inside-clear-color ffffff \
    --separator-color 00000000 \
    --indicator-radius 120 \
    --indicator-thickness 15 \
    --font "Inter" \
    --show-failed-attempts \
    --indicator-caps-lock
