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
    hypridle \
    hyprlock \
    hyprshot \
    waybar \
    cliphist \
    kitty \
    wofi \
    pamixer \
    freerdp \
    greetd \
    tailscale \
    topgrade \
    git \
    cmake \
    gcc \
    gcc-c++ \
    cpio \
    pkgconf-pkg-config \
    meson

# 3. Abilitiamo i servizi di sistema
systemctl enable tailscaled.service
