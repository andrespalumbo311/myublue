#!/bin/bash

set -ouex pipefail

### Install packages
echo "Inizio installazione pacchetti personalizzati..."

# Installiamo COSMIC, Hyprland e i tool essenziali che avevi in layer
dnf5 install -y \
    cosmic-desktop \
    hyprland \
    hypridle \
    hyprlock \
    hyprshot \
    kitty \
    wofi \
    cliphist \
    pamixer \
    freerdp \
    greetd \
    tuigreet \
    tailscale \
    gnome-software

#### Enable System Unit Files
# Abilitiamo i servizi di sistema affinché partano da soli all'avvio

# Abilita il demone di Tailscale in background
systemctl enable tailscaled.service

# Abilita greetd come display manager (la schermata dove metti la password)
systemctl enable greetd.service

# (Opzionale) Mantiene podman.socket abilitato se usi molto i container rootless
systemctl enable podman.socket
