# STAGE 1: Compilazione binari custom (wl-clip-persist e sched-ext)
FROM ghcr.io/ublue-os/base-main:latest AS builder

# Installazione dipendenze per wl-clip-persist e scx
ENV CARGO_HOME=/tmp/cargo
RUN dnf install -y \
    git cargo clang clang-devel llvm-devel \
    libbpf-devel elfutils-libelf-devel zlib-devel \
    make pkgconf wayland-devel bpftool meson

# 1. Compilazione wl-clip-persist
RUN cargo install --git https://github.com/Linus789/wl-clip-persist.git --root /tmp/cargo-build

# 2. Compilazione scx (sched-ext) dal ramo main per supporto Kernel 6.19+
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
COPY --from=builder /tmp/cargo-build/bin/wl-clip-persist /usr/bin/wl-clip-persist
COPY --from=builder /tmp/scx-build/scx_lavd /usr/bin/scx_lavd
COPY --from=builder /tmp/scx-build/scx_rusty /usr/bin/scx_rusty

# STRATO 1: Repository COPR
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 -y copr enable yalter/niri && \
    dnf5 -y copr enable zhangyi6324/noctalia-shell && \
    dnf5 -y copr enable lilay/topgrade && \
    dnf5 -y copr enable ublue-os/packages && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 -y copr enable imput/helium && \
    dnf5 clean all

# STRATO 2: Utilità CLI e System Tooling
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    git cmake gcc gcc-c++ meson micro tailscale topgrade \
    inotify-tools powertop tlp tlp-rdw freerdp \
    uupd ananicy-cpp scx-tools && \
    dnf5 clean all

# STRATO 3: Ambiente Grafico (Base) e Font/Langpacks di sistema
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    niri noctalia-shell fuzzel \
    greetd tuigreet fprintd fprintd-pam \
    dejavu-sans-fonts glibc-all-langpacks && \
    dnf5 clean all

# STRATO 4: Multimedia e Utility Desktop
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    brightnessctl grim slurp \
    pavucontrol cliphist kitty pamixer \
    easyeffects lsp-plugins \
    nautilus gvfs-mtp gvfs-smb \
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-user-dirs-gtk && \
    dnf5 clean all

# STRATO 5: Helium Browser (Metodo forzato per successo installazione)
RUN rm -rf /opt && mkdir -p /opt && \
    dnf5 install -y helium-bin && \
    dnf5 clean all

# STRATO 6: Configurazione servizi e finalizzazione
COPY etc /etc
RUN if id "greetd" &>/dev/null; then \
        usermod -aG video,render,tty greetd; \
    fi && \
    chmod +x /etc/scx/scx-launcher.sh && \
    systemctl enable tailscaled.service greetd.service uupd.timer scx.service ananicy-cpp.service && \
    systemctl --global enable easyeffects.service && \
    systemctl disable rpm-ostreed-automatic.timer bluetooth.service

### LINTING
RUN bootc container lint
