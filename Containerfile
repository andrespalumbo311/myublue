# STAGE 1: Download utility custom
FROM ghcr.io/ublue-os/base-main:latest AS builder

# Installazione dipendenze per download e verifica
RUN dnf install -y curl jq tar xz

# Download e verifica utility (Starship, Topgrade, uupd)
RUN mkdir -p /tmp/verify /tmp/bin && \
    # Starship
    STARSHIP_ASSETS=$(curl -fsSL https://api.github.com/repos/starship/starship/releases/latest) && \
    STARSHIP_URL=$(echo "$STARSHIP_ASSETS" | jq -r '.assets[] | select(.name == "starship-x86_64-unknown-linux-musl.tar.gz") | .browser_download_url') && \
    STARSHIP_SHA=$(echo "$STARSHIP_ASSETS" | jq -r '.assets[] | select(.name == "starship-x86_64-unknown-linux-musl.tar.gz") | .digest' | cut -d: -f2) && \
    curl -fsSL "$STARSHIP_URL" -o /tmp/verify/starship.tar.gz && \
    echo "$STARSHIP_SHA  /tmp/verify/starship.tar.gz" | sha256sum --check && \
    tar -xz -C /tmp/bin -f /tmp/verify/starship.tar.gz starship && \
    # Topgrade
    TOPGRADE_ASSETS=$(curl -fsSL https://api.github.com/repos/topgrade-rs/topgrade/releases/latest) && \
    TOPGRADE_URL=$(echo "$TOPGRADE_ASSETS" | jq -r '.assets[] | select(.name | contains("x86_64-unknown-linux-musl.tar.gz")) | .browser_download_url') && \
    TOPGRADE_SHA=$(echo "$TOPGRADE_ASSETS" | jq -r '.assets[] | select(.name | contains("x86_64-unknown-linux-musl.tar.gz")) | .digest' | cut -d: -f2) && \
    curl -fsSL "$TOPGRADE_URL" -o /tmp/verify/topgrade.tar.gz && \
    echo "$TOPGRADE_SHA  /tmp/verify/topgrade.tar.gz" | sha256sum --check && \
    tar -xz -C /tmp/bin -f /tmp/verify/topgrade.tar.gz topgrade && \
    # uupd
    UUPD_ASSETS=$(curl -fsSL https://api.github.com/repos/ublue-os/uupd/releases/latest) && \
    UUPD_URL=$(echo "$UUPD_ASSETS" | jq -r '.assets[] | select(.name == "uupd_Linux_x86_64.tar.gz") | .browser_download_url') && \
    UUPD_SHA=$(echo "$UUPD_ASSETS" | jq -r '.assets[] | select(.name == "uupd_Linux_x86_64.tar.gz") | .digest' | cut -d: -f2) && \
    curl -fsSL "$UUPD_URL" -o /tmp/verify/uupd.tar.gz && \
    echo "$UUPD_SHA  /tmp/verify/uupd.tar.gz" | sha256sum --check && \
    tar -xz -C /tmp/bin -f /tmp/verify/uupd.tar.gz uupd && \
    chmod +x /tmp/bin/* && \
    rm -rf /tmp/verify

# STAGE 2: Immagine Finale
FROM ghcr.io/ublue-os/base-main:latest

# Copia dei binari custom dallo stage di build
COPY --from=builder /tmp/bin/starship /usr/bin/starship
COPY --from=builder /tmp/bin/topgrade /usr/bin/topgrade
COPY --from=builder /tmp/bin/uupd /usr/bin/uupd

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
    mkdir -p /etc/kernel && \
    echo "initrd_generator=none" > /etc/kernel/install.conf && \
    # Rimozione kernel stock e pulizia moduli per evitare duplicati nel linting
    dnf5 -y --setopt=protected_packages= remove kernel kernel-core kernel-modules kernel-modules-extra && \
    rm -rf /usr/lib/modules/* && \
    # Mocking GRUB per evitare errori in ambiente container durante l'installazione del kernel
    echo -e '#!/bin/sh\nexit 0' > /usr/local/bin/grub2-probe && \
    echo -e '#!/bin/sh\nexit 0' > /usr/local/bin/grub2-editenv && \
    chmod +x /usr/local/bin/grub2-probe /usr/local/bin/grub2-editenv && \
    # Installazione Kernel CachyOS
    dnf5 -y --setopt=protected_packages= install \
        kernel-cachyos-lto sudo-rs uutils-coreutils sbsigntools \
        --allowerasing && \
    rm /etc/kernel/install.conf && \
    ln -sf /usr/bin/sudo-rs /usr/bin/sudo && \
    KVER=$(ls /lib/modules | grep cachyos | head -n 1) && \
    depmod -a $KVER && \
    dracut --kver $KVER --no-hostonly --reproducible --add ostree --force /lib/modules/$KVER/initramfs.img && \
    chmod 0600 /lib/modules/$KVER/initramfs.img && \
    sbsign --key /run/secrets/MOK_key --cert /run/secrets/MOK_crt --output /lib/modules/$KVER/vmlinuz /lib/modules/$KVER/vmlinuz && \
    # Pulizia post-installazione per bootc lint
    rm -rf /boot/* /usr/local/bin/grub2-probe /usr/local/bin/grub2-editenv && \
    setsebool -P domain_kernel_load_modules on && \
    dnf5 -y copr disable bieszczaders/kernel-cachyos-lto && \
    dnf5 -y copr disable dejan/rpms && \
    dnf5 clean all

# STRATO 2: Utilità CLI e System Tooling
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    git tailscale \
    inotify-tools powertop power-profiles-daemon freerdp \
    scx-scheds scx-tools scx-manager flatpak udisks2 \
    python3-pyqt6 \
    parted dosfstools exfatprogs e2fsprogs \
    fish zoxide fzf && \
    sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd && \
    # Ottimizzazione I/O (ADIOS) - Sintassi completa Origami OS
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"' > /etc/udev/rules.d/60-ioschedulers.rules && \
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="adios"' >> /etc/udev/rules.d/60-ioschedulers.rules && \
    echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="adios"' >> /etc/udev/rules.d/60-ioschedulers.rules && \
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
    scx-manager python3-pyqt6 \
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
chmod +x /etc/skel/.config/niri/scripts/*.sh && \
    dconf update && \
    systemctl enable tailscaled.service greetd.service uupd.timer scx.service scx_loader.service power-profiles-daemon.service bluetooth.service bluetooth-poweroff.service && \
    systemctl --global enable easyeffects.service && \
    systemctl disable rpm-ostreed-automatic.timer

# STRATO 5: Inizializzazione Flatpak e Valent
RUN flatpak remote-delete valent || true && \
    flatpak remote-add --if-not-exists --system valent /etc/flatpak/remotes.d/valent.flatpakrepo && \
    flatpak update --appstream valent

### LINTING
RUN bootc container lint
