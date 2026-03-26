FROM scratch AS ctx
COPY build_files /

FROM ghcr.io/ublue-os/base-main:latest

# STRATO 1: Repository COPR
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 -y copr enable sdegler/hyprland && \
    dnf5 -y copr enable lilay/topgrade

# STRATO 2: Compilazione custom wl-clip-persist
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y cargo && \
    CARGO_HOME=/tmp/cargo-home cargo install --git https://github.com/Linus789/wl-clip-persist.git wl-clip-persist --root /tmp/cargo-build && \
    cp /tmp/cargo-build/bin/wl-clip-persist /usr/bin/ && \
    dnf5 remove -y cargo && \
    rm -rf /tmp/cargo-build /tmp/cargo-home

# STRATO 3: Utilità di base e demòni
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    git cmake gcc gcc-c++ meson micro tailscale topgrade \
    inotify-tools powertop tlp tlp-rdw freerdp

# STRATO 4: Utilità grafiche trasversali
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    brightnessctl network-manager-applet blueman grim slurp \
    pavucontrol cliphist kitty wofi pamixer swaybg

# STRATO 5: Ecosistema Hyprland e compilazione dinamica tramite hyprpm isolato
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    export XDG_RUNTIME_DIR=/tmp/runtime-root && \
    export XDG_CACHE_HOME=/tmp/cache-root && \
    export XDG_DATA_HOME=/tmp/data-root && \
    mkdir -p $XDG_RUNTIME_DIR $XDG_CACHE_HOME $XDG_DATA_HOME && \
    dnf5 install -y \
    hyprland waybar hypridle hyprlock hyprshot \
    hyprland-devel aquamarine-devel hyprlang-devel hyprutils-devel \
    glm-devel glibmm24-devel pulseaudio-libs-devel meson ninja-build gcc-c++ cmake git && \
    hyprpm update && \
    hyprpm add https://github.com/horriblename/hyprgrass || true && \
    mkdir -p /usr/lib64/hyprland/plugins && \
    PLUGIN_PATH=$(find $XDG_DATA_HOME/hyprpm -name "libhyprgrass.so" | head -n 1) && \
    if [ -z "$PLUGIN_PATH" ]; then echo "Errore critico: libhyprgrass.so non compilato"; exit 1; fi && \
    cp "$PLUGIN_PATH" /usr/lib64/hyprland/plugins/hyprgrass.so && \
    dnf5 remove -y hyprland-devel aquamarine-devel hyprlang-devel hyprutils-devel glm-devel glibmm24-devel pulseaudio-libs-devel meson ninja-build gcc-c++ cmake && \
    rm -rf $XDG_RUNTIME_DIR $XDG_CACHE_HOME $XDG_DATA_HOME

# STRATO 6: Ecosistema COSMIC
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    @cosmic-desktop-environment

# STRATO 7: Configurazione servizi
RUN systemctl enable tailscaled.service

### LINTING
RUN bootc container lint
