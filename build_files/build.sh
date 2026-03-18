#!/bin/bash
set -ouex pipefail

echo "Inizio installazione pacchetti personalizzati..."

# 1. Abilitiamo i COPR necessari
# Per Hyprland e i suoi tool su Fedora 43
dnf5 -y copr enable sdegler/hyprland
# Per Topgrade (come indicato nella documentazione che hai trovato)
dnf5 -y copr enable lilay/topgrade

# 2. Installiamo tutto il pacchetto
dnf5 install -y \
    @cosmic-desktop-environment \
    hyprland \
    hyprland-devel \
    aquamarine-devel \
    hyprlang-devel \
    hyprutils-devel \
    waybar \
    git \
    cmake \
    gcc \
    gcc-c++ \
    meson \
    brightnessctl \
    network-manager-applet \
    blueman \
    micro \
    grim \
    slurp \
    pavucontrol \
    hypridle \
    hyprlock \
    hyprshot \
    cliphist \
    kitty \
    wofi \
    pamixer \
    freerdp \
    tailscale \
    topgrade \
    inotify-tools \
    swaybg \
    powertop

# Compilazione e installazione di wl-clip-persist
echo "Compilazione wl-clip-persist..."
dnf5 install -y cargo
# Scarichiamo e compiliamo direttamente dal repository GitHub ufficiale
CARGO_HOME=/tmp/cargo-home cargo install --git https://github.com/Linus789/wl-clip-persist.git wl-clip-persist --root /tmp/cargo-build
cp /tmp/cargo-build/bin/wl-clip-persist /usr/bin/
dnf5 remove -y cargo
rm -rf /tmp/cargo-build /tmp/cargo-home

# 3. Abilitiamo i servizi di sistema
systemctl enable tailscaled.service
