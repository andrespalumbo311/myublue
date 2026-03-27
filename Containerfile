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

# STRATO 5: Ecosistema Hyprland e compilazione deterministica
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    hyprland waybar hypridle hyprlock hyprshot \
    hyprland-devel aquamarine-devel hyprlang-devel hyprutils-devel \
    glm-devel glibmm24-devel pulseaudio-libs-devel meson ninja-build gcc-c++ cmake python3 && \
    git clone https://github.com/horriblename/hyprgrass.git /tmp/hyprgrass && \
    cd /tmp/hyprgrass && \
    HL_VER=$(pkg-config --modversion hyprland) && \
    TARGET=$(python3 -c "import tomllib, sys; d=tomllib.load(open('hyprpm.toml', 'rb')); print(next((r['hash'] for r in d.get('revisions', []) if sys.argv[1] in r.get('hyprland', '')), ''))" "$HL_VER") && \
    if [ -n "$TARGET" ]; then git checkout "$TARGET"; fi && \
    meson setup build && \
    ninja -C build && \
    mkdir -p /usr/lib64/hyprland/plugins && \
    cp build/src/libhyprgrass.so /usr/lib64/hyprland/plugins/hyprgrass.so && \
    rm -rf /tmp/hyprgrass && \
    dnf5 remove -y hyprland-devel aquamarine-devel hyprlang-devel hyprutils-devel glm-devel glibmm24-devel pulseaudio-libs-devel meson ninja-build gcc-c++ cmake python3

# STRATO 6: Ecosistema COSMIC
RUN --mount=type=cache,dst=/var/cache --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    @cosmic-desktop-environment

# STRATO 7: Configurazione servizi
RUN systemctl enable tailscaled.service

### LINTING
RUN bootc container lint
