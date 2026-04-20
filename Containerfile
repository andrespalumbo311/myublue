# STAGE 1: Compilazione binari custom (wl-clip-persist)
# Usiamo un multi-stage build per mantenere l'immagine finale pulita e massimizzare la cache.
FROM fedora:41 AS builder
RUN dnf install -y cargo git wayland-devel && \
    cargo install --git https://github.com/Linus789/wl-clip-persist.git --root /tmp/cargo-build

# STAGE 2: Immagine Finale
FROM ghcr.io/ublue-os/base-main:latest

# Copia dei binari custom dallo stage di build (Ottimizzazione: nessun residuo di Cargo o build-deps)
COPY --from=builder /tmp/cargo-build/bin/wl-clip-persist /usr/bin/wl-clip-persist

# STRATO 1: Repository COPR
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 -y copr enable yalter/niri && \
    dnf5 -y copr enable zhangyi6324/noctalia-shell && \
    dnf5 -y copr enable lilay/topgrade && \
    dnf5 -y copr enable ublue-os/packages && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 clean all

# STRATO 2: Utilità CLI e System Tooling (Cambiamenti rari)
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    git cmake gcc gcc-c++ meson micro tailscale topgrade \
    inotify-tools powertop tlp tlp-rdw freerdp \
    uupd scx-scheds ananicy-cpp && \
    dnf5 clean all

# STRATO 3: Ambiente Grafico e Utility (Cambiamenti più frequenti)
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    niri noctalia-shell fuzzel \
    greetd tuigreet fprintd fprintd-pam \
    brightnessctl grim slurp \
    pavucontrol cliphist kitty pamixer \
    easyeffects lsp-plugins \
    nautilus gvfs-mtp gvfs-smb \
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-user-dirs-gtk && \
    dnf5 clean all

# STRATO 4: Configurazione servizi e finalizzazione
COPY etc /etc
RUN if id "greetd" &>/dev/null; then \
        usermod -aG video,render,tty greetd; \
    fi && \
    systemctl enable tailscaled.service greetd.service uupd.timer scx.service ananicy-cpp.service && \
    systemctl --global enable uupd.timer easyeffects.service && \
    systemctl disable rpm-ostreed-automatic.timer bluetooth.service
### LINTING
RUN bootc container lint
