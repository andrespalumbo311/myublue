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
    distrobox \
    ffmpeg \
    git \
    cmake \
    gcc \
    gcc-c++ \
    meson \
    cpio \
    pkgconf-pkg-config \
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
    ImageMagick \
    inotify-tools \
    swaybg

# 3. Abilitiamo i servizi di sistema
systemctl enable tailscaled.service
