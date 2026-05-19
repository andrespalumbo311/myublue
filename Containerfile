# STAGE 1: Compilazione binari custom (sched-ext) e utility
FROM ghcr.io/ublue-os/base-main:latest AS builder

# Installazione dipendenze per scx e download utility
ENV CARGO_HOME=/tmp/cargo
RUN dnf install -y \
    git cargo clang clang-devel llvm-devel \
    libbpf-devel elfutils-libelf-devel zlib-devel \
    make pkgconf bpftool meson curl jq tar xz

# Compilazione scx (sched-ext)
RUN git clone --recursive https://github.com/sched-ext/scx.git /tmp/scx && \
    cd /tmp/scx && \
    cargo build --release --package scx_lavd --package scx_rusty && \
    mkdir -p /tmp/scx-build && \
    cp target/release/scx_lavd /tmp/scx-build/ && \
    cp target/release/scx_rusty /tmp/scx-build/

# Download utility (Starship, Topgrade, uupd)
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir /tmp/scx-build && \
    TOPGRADE_URL=$(curl -fsSL https://api.github.com/repos/topgrade-rs/topgrade/releases/latest | jq -r '.assets[] | select(.name | contains("x86_64-unknown-linux-musl")) | .browser_download_url') && \
    curl -fsSL "$TOPGRADE_URL" | tar -xz -C /tmp/scx-build topgrade && \
    UUPD_URL=$(curl -fsSL https://api.github.com/repos/ublue-os/uupd/releases/latest | jq -r '.assets[] | select(.name | contains("uupd_Linux_x86_64")) | .browser_download_url') && \
    curl -fsSL "$UUPD_URL" | tar -xz -C /tmp/scx-build uupd && \
    chmod +x /tmp/scx-build/topgrade /tmp/scx-build/uupd

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
    dnf5 -y copr enable bieszczaders/kernel-cachyos-lto && \
    dnf5 -y copr enable dejan/rpms && \
    dnf5 clean all

# SWAP KERNEL, SUDO E UTILITY RUST + FIRMA SECUREBOOT
RUN --mount=type=secret,id=MOK_key \
    --mount=type=secret,id=MOK_crt \
    --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 -y --setopt=protected_packages= install \
        kernel-cachyos-lto sudo-rs uutils-coreutils sbsigntools openssl \
        --allowerasing && \
    ln -sf /usr/bin/sudo-rs /usr/bin/sudo && \
    KVER=$(ls /lib/modules | head -n 1) && \
    sbsign --key /run/secrets/MOK_key --cert /run/secrets/MOK_crt --output /lib/modules/$KVER/vmlinuz /lib/modules/$KVER/vmlinuz && \
    setsebool -P domain_kernel_load_modules on && \
    dnf5 -y copr disable bieszczaders/kernel-cachyos-lto && \
    dnf5 -y copr disable dejan/rpms && \
    dnf5 clean all

# STRATO 2: Utilità CLI e System Tooling
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    git tailscale \
    inotify-tools powertop power-profiles-daemon freerdp \
    scx-tools flatpak udisks2 \
    parted dosfstools exfatprogs e2fsprogs \
    fish zoxide fzf && \
    sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd && \
    # Ottimizzazione I/O (ADIOS)
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="adios"' > /etc/udev/rules.d/60-ioschedulers.rules && \
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
    libva-intel-media-driver libva-utils \
    easyeffects lsp-plugins \
    nautilus gvfs-mtp gvfs-smb \
    gnome-keyring gnome-keyring-pam \
    cups-pk-helper kf6-kimageformats qt6-qtimageformats \
    accountsservice \
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-user-dirs-gtk && \
    dnf5 remove -y swaybg swaylock swayidle cliphist fuzzel mako dunst || true && \
    dnf5 clean all

# STRATO 4: Configurazione servizi e finalizzazione
RUN mkdir -p /etc/pki/akmods/certs/
COPY etc /etc
COPY usr /usr
COPY MOK.der /etc/pki/akmods/certs/public_key.der
RUN if id "greetd" &>/dev/null; then \
        usermod -aG video,render,tty greetd; \
    fi && \
    chmod +x /etc/scx/scx-launcher.sh && \
    chmod +x /etc/skel/.config/niri/scripts/*.sh && \
    dconf update && \
    systemctl enable tailscaled.service greetd.service uupd.timer scx.service power-profiles-daemon.service bluetooth.service bluetooth-poweroff.service && \
    systemctl --global enable easyeffects.service && \
    systemctl disable rpm-ostreed-automatic.timer

# STRATO 5: Inizializzazione Flatpak e Valent
RUN flatpak remote-delete valent || true && \
    flatpak remote-add --if-not-exists --system valent /etc/flatpak/remotes.d/valent.flatpakrepo && \
    flatpak update --appstream valent

### LINTING
RUN bootc container lint
