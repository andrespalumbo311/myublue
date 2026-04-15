# STAGE 1: Compilazione binari custom (wl-clip-persist)
# Usiamo un multi-stage build per mantenere l'immagine finale pulita e massimizzare la cache.
FROM fedora:41 AS builder
RUN dnf install -y cargo git wayland-devel && \
    cargo install --git https://github.com/Linus789/wl-clip-persist.git --root /tmp/cargo-build

# STAGE 2: Immagine Finale
FROM ghcr.io/ublue-os/base-main:latest

# Copia dei binari custom dallo stage di build (Ottimizzazione: nessun residuo di Cargo o build-deps)
COPY --from=builder /tmp/cargo-build/bin/wl-clip-persist /usr/bin/wl-clip-persist

# STRATO 1: Repository COPR (Sostituito Hyprland con Niri e Noctalia)
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 -y copr enable yalter/niri && \
    dnf5 -y copr enable zhangyi6324/noctalia-shell && \
    dnf5 -y copr enable lilay/topgrade && \
    dnf5 -y copr enable scottames/awww

# STRATO 2: Utilità CLI e System Tooling
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    git cmake gcc gcc-c++ meson micro tailscale topgrade \
    inotify-tools powertop tlp tlp-rdw freerdp

# STRATO 3: Ambiente Grafico Niri + Noctalia (Rimossi Hyprland, Waybar e Wofi)
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    niri noctalia-shell fuzzel \
    brightnessctl grim slurp \
    pavucontrol cliphist kitty pamixer awww

# STRATO 4: Ecosistema COSMIC (Mantenuto come backup DE completo)
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    @cosmic-desktop-environment

# STRATO 5: Configurazione servizi e finalizzazione
COPY etc /etc
RUN systemctl enable tailscaled.service

### LINTING
RUN bootc container lint
