# STAGE 1: Compilazione binari custom (sched-ext) e utility
FROM ghcr.io/ublue-os/base-main:latest AS builder

# Installazione dipendenze per scx e download utility
ENV CARGO_HOME=/tmp/cargo
RUN dnf install -y \
    git cargo clang clang-devel llvm-devel \
    libbpf-devel elfutils-libelf-devel zlib-devel \
    make pkgconf bpftool meson curl jq

# Compilazione scx (sched-ext)
RUN git clone --recursive https://github.com/sched-ext/scx.git /tmp/scx && \
    cd /tmp/scx && \
    cargo build --release --package scx_lavd --package scx_rusty && \
    mkdir -p /tmp/scx-build && \
    cp target/release/scx_lavd /tmp/scx-build/ && \
    cp target/release/scx_rusty /tmp/scx-build/

# Download utility (Starship, Topgrade, uupd)
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir /tmp/scx-build && \
    TOPGRADE_URL=$(curl -s https://api.github.com/repos/topgrade-rs/topgrade/releases/latest | jq -r '.assets[] | select(.name | contains("x86_64-unknown-linux-musl")) | .browser_download_url') && \
    curl -L "$TOPGRADE_URL" | tar -xz -C /tmp/scx-build --strip-components=1 || curl -L "$TOPGRADE_URL" | tar -xz -C /tmp/scx-build && \
    UUPD_URL=$(curl -s https://api.github.com/repos/ublue-os/uupd/releases/latest | jq -r '.assets[] | select(.name == "uupd") | .browser_download_url') && \
    curl -L -o /tmp/scx-build/uupd "$UUPD_URL" && \
    chmod +x /tmp/scx-build/uupd

# STAGE 2: Immagine Finale
FROM ghcr.io/ublue-os/base-main:latest

# Copia dei binari custom dallo stage di build
COPY --from=builder /tmp/scx-build/scx_lavd /usr/bin/scx_lavd
COPY --from=builder /tmp/scx-build/scx_rusty /usr/bin/scx_rusty
COPY --from=builder /tmp/scx-build/starship /usr/bin/starship
COPY --from=builder /tmp/scx-build/topgrade /usr/bin/topgrade
COPY --from=builder /tmp/scx-build/uupd /usr/bin/uupd

# STRATO 1: Repository COPR (Manteniamo per ananicy-cpp e altri tool)
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 -y copr enable yalter/niri && \
    dnf5 -y copr enable avengemedia/dms && \
    dnf5 -y copr enable avengemedia/danklinux && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 clean all

# STRATO 2: Utilità CLI e System Tooling
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    git tailscale \
    inotify-tools powertop tlp tlp-rdw freerdp \
    ananicy-cpp scx-tools flatpak udisks2 \
    parted dosfstools exfatprogs e2fsprogs \
    fish zoxide fzf && \
    sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd && \
    dnf5 clean all

# Installazione plugin Bass (per compatibilità script Bash in Fish)
RUN git clone https://github.com/edc/bass.git /tmp/bass && \
    mkdir -p /usr/share/fish/vendor_functions.d && \
    cp /tmp/bass/functions/bass.fish /usr/share/fish/vendor_functions.d/ && \
    rm -rf /tmp/bass

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
    cups-pk-helper kf6-kimageformats qt6-qtimageformats \
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
