ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME}"
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS quark

ARG IMAGE_NAME="${IMAGE_NAME:-quark}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"

COPY system_files /
COPY --from=ghcr.io/ublue-os/config:latest /rpms /tmp/rpms/config

# Setup repos and ublue-os config rpms
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    wget https://github.com/trgeiger/cpm/releases/download/v1.0.3/cpm -O /usr/bin/cpm && chmod +x /usr/bin/cpm && \
    cpm enable \
        che/nerd-fonts \
        kylegospo/bazzite \
        ublue-os/staging \
        sentry/switcheroo-control_discrete \
        bieszczaders/kernel-cachyos-addons \
        bieszczaders/kernel-cachyos && \
    cpm enable -m \
        kylegospo/bazzite-multilib && \
    rm -rf /tmp/rpms/config/ublue-os-update-services.*.rpm && \
    rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
        /tmp/rpms/config/*.rpm \
        fedora-repos-archive && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Update packages that commonly cause build issues
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        vulkan-loader \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        alsa-lib \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        gnutls \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        glib2 \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        nspr \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        nss \
        nss-softokn \
        nss-softokn-freebl \
        nss-sysinit \
        nss-util \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        atk \
        at-spi2-atk \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libaom \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        gstreamer1 \
        gstreamer1-plugins-base \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libdecor \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libtirpc \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libuuid \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libblkid \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libmount \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        cups-libs \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libinput \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libopenmpt \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        llvm-libs \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        zlib-ng-compat \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        fontconfig \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        pciutils-libs \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libdrm \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        cpp \
        libatomic \
        libgcc \
        libgfortran \
        libgomp \
        libobjc \
        libstdc++ \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libX11 \
        libX11-common \
        libX11-xcb \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        libv4l \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
        elfutils-libelf \
        elfutils-libs \
        || true && \
    rpm-ostree override remove \
        glibc32 \
        || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# use negativo17 for 3rd party packages with higher priority than default
RUN curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo && \
    sed -i '0,/enabled=1/{s/enabled=1/enabled=1\npriority=90/}' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    rpm-ostree override replace \
    --experimental \
    --from repo='fedora-multimedia' \
        libheif \
        libva \
        libva-intel-media-driver \
        mesa-dri-drivers \
        mesa-filesystem \
        mesa-libEGL \
        mesa-libGL \
        mesa-libgbm \
        mesa-libglapi \
        mesa-libxatracker \
        mesa-va-drivers \
        mesa-vulkan-drivers

# Install CachyOS kernel
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree cliwrap install-to-root / && \
    rpm-ostree override remove \
            kernel \
            kernel-core \
            kernel-modules \
            kernel-modules-core \
            kernel-modules-extra \
        --install \
            kernel-cachyos \
        --install \
            kernel-cachyos-devel-matched && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install Valve's patched Mesa, Pipewire, Bluez, and Xwayland
# Install patched switcheroo control with proper discrete GPU support
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/rpmfusion-*.repo && \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:kylegospo:bazzite-multilib \
        mesa-libxatracker \
        mesa-libglapi \
        mesa-dri-drivers \
        mesa-libgbm \
        mesa-libEGL \
        mesa-vulkan-drivers \
        mesa-libGL \
        pipewire \
        pipewire-alsa \
        pipewire-gstreamer \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit-libs \
        pipewire-libs \
        pipewire-pulseaudio \
        pipewire-utils \
        pipewire-plugin-libcamera \
        bluez \
        bluez-obexd \
        bluez-cups \
        bluez-libs \
        xorg-x11-server-Xwayland && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/rpmfusion-*.repo && \
    rpm-ostree install \
        libaacs \
        libbdplus \
        libbluray && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/rpmfusion-*.repo && \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/rpmfusion-*.repo && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Removals
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
        libavdevice-free \
        libavfilter-free \
        libavformat-free \
        ffmpeg-free \
        libpostproc-free \
        libswresample-free \
        libavutil-free \
        libavcodec-free \
        libswscale-free \
        google-noto-sans-cjk-vf-fonts \
        mesa-va-drivers \
        default-fonts-cjk-sans \
        firefox \
        firefox-langpacks && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# CachyOS addons
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
        scx-scheds && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Additions
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
        alsa-firmware \
        apr \
        apr-util \
        adw-gtk3-theme \
        cascadia-code-fonts \
        default-fonts-cjk-sans \
        distrobox \
        drm_info \
        fastfetch \
        ffmpeg \
        ffmpegthumbnailer \
        fuse-libs \
        fzf \
        google-noto-sans-balinese-fonts \
        google-noto-sans-cjk-fonts \
        google-noto-sans-javanese-fonts \
        google-noto-sans-sundanese-fonts \
        grub2-tools-extra \
        htop \
        just \
        kernel-tools \
        libratbag-ratbagd \
        lshw \
        mpv \
        nerd-fonts \
        net-tools \
        nvme-cli \
        nvtop \
        openrgb-udev-rules \
        openssl \
        pam-u2f \
        pam_yubico \
        pamu2fcfg \
        smartmontools \
        solaar-udev \
        symlinks \
        tcpdump \
        tmux \
        traceroute \
        vim \
        wireguard-tools \
        zstd \
        bootc \
        duperemove \
        edid-decode \
        glibc.i686 \
        jetbrains-mono-fonts \
        jq \
        mesa-libGLU \
        patch \
        powertop \
        python3-pip \
        rsms-inter-fonts \
        setools \
        sysfsutils \
        tuned \
        tuned-gtk \
        tuned-ppd \
        tuned-profiles-cpu-partitioning \
        tuned-utils \
        i2c-tools \
        unrar \
        vulkan-tools \
        wl-clipboard \
        xrandr \
        x265 \
        zsh && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/mpv.desktop && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Gnome stuff
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        gnome-shell && \
    rpm-ostree override replace \
    --experimental \
    --from repo=tayler \
        mutter \
        mutter-common && \
    rpm-ostree install \
        gnome-randr-rust \
        gnome-epub-thumbnailer \
        gnome-tweaks \
        gnome-shell-extension-blur-my-shell \
        gnome-shell-extension-caffeine \
        gnome-shell-extension-just-perfection \
        gnome-shell-extension-hotedge && \
    rpm-ostree override remove \
        gnome-tour \
        gnome-extensions-app \
        gnome-classic-session \
        gnome-shell-extension-background-logo \
        gnome-shell-extension-apps-menu && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Gaming-specific changes
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    if [[ "${IMAGE_NAME}" == "quark" ]]; then \
    rpm-ostree install \
        jupiter-sd-mounting-btrfs \
        at-spi2-core.i686 \
        atk.i686 \
        vulkan-loader.i686 \
        alsa-lib.i686 \
        fontconfig.i686 \
        gtk2.i686 \
        libICE.i686 \
        libnsl.i686 \
        libxcrypt-compat.i686 \
        libpng12.i686 \
        libXext.i686 \
        libXinerama.i686 \
        libXtst.i686 \
        libXScrnSaver.i686 \
        NetworkManager-libnm.i686 \
        nss.i686 \
        pulseaudio-libs.i686 \
        libcurl.i686 \
        systemd-libs.i686 \
        libva.i686 \
        libvdpau.i686 \
        libdbusmenu-gtk3.i686 \
        libatomic.i686 \
        pipewire-alsa.i686 \
        gobject-introspection \
        clinfo \
        steam && \
    rpm-ostree install \
        wine-core.x86_64 \
        wine-core.i686 \
        wine-pulseaudio.x86_64 \
        wine-pulseaudio.i686 \
        libFAudio.x86_64 \
        libFAudio.i686 \
        winetricks \
        mesa-vulkan-drivers.i686 \
        mesa-va-drivers.i686 \
        gamescope.x86_64 \
        gamescope-libs.i686 \
        gamescope-shaders \ 
        vkBasalt.x86_64 \
        vkBasalt.i686 \
        mangohud.x86_64 \
        mangohud.i686 \
        protontricks \
        intel-undervolt && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/yad-icon-browser.desktop && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/winetricks.desktop && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/protontricks.desktop && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit \
    ; fi

# run post-install tasks and clean up
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    rm -f /etc/pki/akmods/private/private_key.priv && \
    rm -f /etc/pki/akmods/certs/public_key.der && \
    rm -f /usr/share/vulkan/icd.d/lvp_icd.*.json && \
    rm -f /usr/share/applications/htop.desktop && \
    rm -f /usr/share/applications/nvtop.desktop && \
    rm -f /usr/share/applications/shredder.desktop && \
    mkdir -p /usr/etc/flatpak/remotes.d && \
    wget -q https://dl.flathub.org/repo/flathub.flatpakrepo -P /usr/etc/flatpak/remotes.d && \
    sed -i 's@Name=tuned-gui@Name=TuneD Manager@g' /usr/share/applications/tuned-gui.desktop && \
    curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" && \
    tar -xzf /tmp/starship.tar.gz -C /tmp && \
    install -c -m 0755 /tmp/starship /usr/bin && \
    echo 'eval "$(starship init bash)"' >> /etc/bashrc && \
    echo 'eval "$(starship init zsh)"' >> /etc/zshrc && \
    systemctl enable tuned.service && \
    systemctl enable dconf-update.service && \
    systemctl disable rpm-ostreed-automatic.timer && \
    systemctl --global enable podman.socket && \
    systemctl --global enable systemd-tmpfiles-setup.service && \
    echo "import \"/usr/share/ublue-os/just/80-quark.just\"" >> /usr/share/ublue-os/justfile && \
    sed -i '/^PRETTY_NAME/s/Silverblue/Quark/' /usr/lib/os-release && \
    sed -i 's/^NAME=.*/NAME="Quark"/' /usr/lib/os-release && \
    fc-cache --system-only --really-force --verbose && \
    /usr/libexec/containerbuild/image-info && \
    /usr/libexec/containerbuild/build-initramfs && \
    /usr/libexec/containerbuild/cleanup.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit


# cloud development build
FROM quark as quark-cloud-dev

ARG IMAGE_NAME="${IMAGE_NAME:-quark-cloud-dev}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

# Install Openshift tools -- oc, opm, kubectl, operator-sdk, odo, helm, crc
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    export VER=$(curl --silent -qI https://github.com/operator-framework/operator-sdk/releases/latest | \
    awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}') && \
    wget https://github.com/operator-framework/operator-sdk/releases/download/$VER/operator-sdk_linux_amd64 -O /usr/bin/operator-sdk && \
    chmod +x /usr/bin/operator-sdk && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz | tar xvzf - -C /usr/bin && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/opm-linux.tar.gz | tar xvzf - -C /usr/bin && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 -o /usr/bin/helm && chmod +x /usr/bin/helm && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/odo/latest/odo-linux-amd64 -o /usr/bin/odo && chmod +x /usr/bin/odo && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/crc/latest/crc-linux-amd64.tar.xz | tar xfJ - --strip-components 1 -C /usr/bin && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit


# Install Kind
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/bin/kind && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install awscli
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -SL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/bin --install-dir /usr/bin && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo && rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    rpm-ostree install \
        code \
        make \
        qemu \
        libvirt \
        virt-manager && \
        rm -f /var/lib/unbound/root.key && \
        /usr/libexec/containerbuild/cleanup.sh && \
        ostree container commit

RUN cpm remove --all && \
    rm -f get_helm.sh && \
    rm -rf aws && \
    rm -f awscliv2.zip && \
    rm -f /usr/bin/README.md && \
    rm -f /usr/bin/LICENSE && \
    sed -i '/^PRETTY_NAME/s/Quark/Quark Cloud Dev/' /usr/lib/os-release && \
    sed -i 's/^NAME=.*/NAME="Quark Cloud Dev"/' /usr/lib/os-release && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit
