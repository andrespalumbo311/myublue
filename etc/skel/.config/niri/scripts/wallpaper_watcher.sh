#!/bin/bash
# Replicazione esatta del watcher Hyprland per Niri
XOPP_FILE="$HOME/Pictures/task_wallpaper.xopp"
PNG_BASE="$HOME/Pictures/task_wallpaper_base.png"
APPLY_SCRIPT="$HOME/.config/niri/scripts/niri-apply-wallpaper.sh"

echo "Watcher (Hyprland mode) avviato..."

while true; do
    inotifywait -m -q -e close_write,moved_to --format "%f" "$(dirname "$XOPP_FILE")" | while read -r filename; do
        if [ "$filename" = "task_wallpaper.xopp" ]; then
            # Delay fondamentale per Xournal++ Flatpak
            sleep 2

            # Pulizia file temporanei numerati
            rm -f "$HOME/Pictures/task_wallpaper_base-"*.png

            # Esportazione con priorità bassa per non rallentare il sistema
            nice -n 19 flatpak run com.github.xournalpp.xournalpp --create-img="$PNG_BASE" "$XOPP_FILE" >/dev/null 2>&1
            
            # Gestione della rinomina se Xournal++ ha creato un file numerato
            for file in "$HOME/Pictures/task_wallpaper_base-"*.png; do
                if [ -f "$file" ]; then
                    mv "$file" "$PNG_BASE" 2>/dev/null
                    break
                fi
            done
            
            # Applicazione wallpaper
            bash "$APPLY_SCRIPT"
        fi
    done
    sleep 2
done
