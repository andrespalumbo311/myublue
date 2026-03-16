#!/bin/bash
set -ouex pipefail

echo "Inizio installazione pacchetti personalizzati..."

# 1. Abilitiamo il COPR della community funzionante per Fedora 43
dnf5 -y copr enable sdegler/hyprland

# 2. Installiamo COSMIC (come gruppo) e i pacchetti di Hyprland (dal COPR)
dnf5 install -y \
    @cosmic-desktop-environment \
    hyprland \
    hyprwayland-scanner \
    hypridle \
    hyprlock \
    hyprshot \
    cliphist \
    kitty \
    wofi \
    pamixer \
    freerdp \
    greetd \
    tuigreet \
    tailscale \
    gnome-software

# Abilitiamo i servizi di sistema necessari
systemctl enable tailscaled.service
systemctl enable greetd.service
