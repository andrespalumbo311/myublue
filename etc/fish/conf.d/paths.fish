# External Paths for Fish (Homebrew and Flatpak)

# Homebrew
if test -d /home/linuxbrew/.linuxbrew/bin
    fish_add_path /home/linuxbrew/.linuxbrew/bin
    fish_add_path /home/linuxbrew/.linuxbrew/sbin
end

# Flatpak
if test -d /var/lib/flatpak/exports/bin
    fish_add_path /var/lib/flatpak/exports/bin
end

if test -d $HOME/.local/share/flatpak/exports/bin
    fish_add_path $HOME/.local/share/flatpak/exports/bin
end
