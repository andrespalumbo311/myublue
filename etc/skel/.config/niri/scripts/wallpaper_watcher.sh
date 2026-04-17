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
            
            # Gestione della rinomina per usare ESCLUSIVAMENTE la prima pagina
            # (evita il bug di globbing dove -10.png viene prima di -1.png)
            if [ -f "${PNG_BASE%.png}-1.png" ]; then
                mv "${PNG_BASE%.png}-1.png" "$PNG_BASE" 2>/dev/null
            fi
            
            # Pulizia file temporanei di eventuali altre pagine (es. -2.png, -3.png...)
            rm -f "${PNG_BASE%.png}-"*.png
            
            # Applicazione wallpaper
            bash "$APPLY_SCRIPT"
        fi
    done
    sleep 2
done
