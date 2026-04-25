# STAGE 1: Compilazione binari custom (sched-ext)
FROM ghcr.io/ublue-os/base-main:latest AS builder

# Installazione dipendenze per scx
ENV CARGO_HOME=/tmp/cargo
RUN dnf install -y \
    git cargo clang clang-devel llvm-devel \
    libbpf-devel elfutils-libelf-devel zlib-devel \
    make pkgconf bpftool meson

# Compilazione scx (sched-ext) dal ramo main per supporto Kernel 6.19+
RUN git clone --recursive https://github.com/sched-ext/scx.git /tmp/scx && \
    cd /tmp/scx && \
    # Build degli scheduler in Rust (lavd, rusty, ecc.)
    cargo build --release --package scx_lavd --package scx_rusty && \
    mkdir -p /tmp/scx-build && \
    cp target/release/scx_lavd /tmp/scx-build/ && \
    cp target/release/scx_rusty /tmp/scx-build/

# STAGE 2: Immagine Finale
FROM ghcr.io/ublue-os/base-main:latest

# Copia dei binari custom dallo stage di build
COPY --from=builder /tmp/scx-build/scx_lavd /usr/bin/scx_lavd
COPY --from=builder /tmp/scx-build/scx_rusty /usr/bin/scx_rusty

# STRATO 1: Repository COPR (Manteniamo per ananicy-cpp e altri tool)
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 -y copr enable yalter/niri && \
    dnf5 -y copr enable avengemedia/dms && \
    dnf5 -y copr enable avengemedia/danklinux && \
    dnf5 -y copr enable lilay/topgrade && \
    dnf5 -y copr enable ublue-os/packages && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 clean all

# STRATO 2: Utilità CLI e System Tooling
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    git cmake gcc gcc-c++ meson micro tailscale topgrade \
    inotify-tools powertop tlp tlp-rdw freerdp \
    uupd ananicy-cpp scx-tools matugen jq flatpak udisks2 \
    parted dosfstools exfatprogs e2fsprogs && \
    dnf5 clean all

# STRATO 3: Ambiente Grafico e Utility
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    niri dms dms-greeter \
    xdg-desktop-portal-wlr \
    greetd tuigreet fprintd fprintd-pam \
    brightnessctl grim slurp \
    pavucontrol kitty pamixer \
    easyeffects lsp-plugins \
    nautilus gvfs-mtp gvfs-smb \
    gnome-keyring \
    cups-pk-helper kf6-kimageformats qt6-qtimageformats ImageMagick khal \
    accountsservice \
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-user-dirs-gtk && \
    dnf5 remove -y swaybg swaylock swayidle cliphist fuzzel mako dunst || true && \
    dnf5 clean all

# STRATO 4: Configurazione servizi e finalizzazione
COPY etc /etc
COPY usr /usr
RUN if id "greetd" &>/dev/null; then \
        usermod -aG video,render,tty greetd; \
    fi && \
    chmod +x /etc/scx/scx-launcher.sh && \
    dconf update && \
    systemctl enable tailscaled.service greetd.service uupd.timer scx.service ananicy-cpp.service bluetooth.service bluetooth-poweroff.service helium-setup.service && \
    systemctl --global enable easyeffects.service && \
    systemctl disable rpm-ostreed-automatic.timer

# STRATO 5: Inizializzazione Flatpak e Valent
RUN flatpak remote-delete valent || true && \
    flatpak remote-add --if-not-exists --system valent /etc/flatpak/remotes.d/valent.flatpakrepo && \
    flatpak update --appstream valent

# STRATO 6: Helium Flatpak (Pre-download latest x86_64 bundle)
RUN mkdir -p /usr/share/helium && \
    HELIUM_URL=$(curl -s https://api.github.com/repos/ShyVortex/helium-flatpak/releases/latest | jq -r '.assets[] | select(.name | contains("x86_64")) | .browser_download_url') && \
    curl -L -o /usr/share/helium/helium.flatpak "$HELIUM_URL"

### LINTING
RUN bootc container lint
