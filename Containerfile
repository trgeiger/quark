ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME}"
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/${SOURCE_IMAGE}"
ARG KERNEL_NAME="${KERNEL_NAME:-kernel-cachyos}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS quark

ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_NAME="${IMAGE_NAME:-quark}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG KERNEL_NAME="${KERNEL_NAME:-kernel-cachyos}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"

COPY system_files /
COPY --from=ghcr.io/ublue-os/config:latest /rpms /tmp/rpms/config

# Update packages
RUN dnf5 -y upgrade

# Setup repos and ublue-os config rpms
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    wget https://github.com/trgeiger/cpm/releases/download/v1.0.3/cpm -O /usr/bin/cpm && chmod +x /usr/bin/cpm && \
    cpm enable \
        che/nerd-fonts \
        kylegospo/bazzite \
        ublue-os/staging \
        sentry/switcheroo-control_discrete \
        bieszczaders/kernel-cachyos \
        bieszczaders/kernel-cachyos-addons && \
    rm -rf /tmp/rpms/config/ublue-os-update-services.*.rpm && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
        /tmp/rpms/config/*.rpm \
        fedora-repos-archive && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

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
            "${KERNEL_NAME}" \
        --install \
            "${KERNEL_NAME}"-devel-matched && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit


# Removals
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    dnf5 -y remove \
        google-noto-sans-cjk-vf-fonts \
        mesa-va-drivers \
        default-fonts-cjk-sans \
        firefox \
        firefox-langpacks && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Additions and swaps
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    dnf5 -y swap \
        ffmpeg-free ffmpeg --allowerasing && \
    dnf5 -y install \
        adw-gtk3-theme \
        alsa-firmware \
        apr \
        apr-util \
        bootc \
        btrfsmaintenance \
        cascadia-code-fonts \
        default-fonts-cjk-sans \
        distrobox \
        drm_info \
        duperemove \
        edid-decode \
        fastfetch \
        ffmpegthumbnailer \
        fuse-libs \
        fzf \
        gh \
        glibc.i686 \
        google-noto-sans-balinese-fonts \
        google-noto-sans-cjk-fonts \
        google-noto-sans-javanese-fonts \
        google-noto-sans-sundanese-fonts \
        grub2-tools-extra \
        htop \
        i2c-tools \
        jetbrains-mono-fonts \
        jq \
        just \
        kernel-tools \
        libheif \
        libratbag-ratbagd \
        libva \
        libva-intel-media-driver \
        lshw \
        mesa-libGLU \
        mpv \
        nerd-fonts \
        net-tools \
        nvme-cli \
        nvtop \
        openrgb-udev-rules \
        openssl \
        pam_yubico \
        pam-u2f \
        pamu2fcfg \
        patch \
        powertop \
        python3-pip \
        rsms-inter-fonts \
        scx-scheds \
        setools \
        smartmontools \
        solaar-udev \
        symlinks \
        sysfsutils \
        tcpdump \
        tmux \
        traceroute \
        tuned \
        tuned-gtk \
        tuned-ppd \
        tuned-profiles-cpu-partitioning \
        tuned-utils \
        unrar \
        vim \
        vulkan-tools \
        wireguard-tools \
        wl-clipboard \
        x265 \
        xrandr \
        zsh \
        zstd && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/mpv.desktop && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Desktop environment stuff
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    if [[ "${BASE_IMAGE_NAME}" == "silverblue" ]]; then \
    dnf5 -y upgrade --repo copr:copr.fedorainfracloud.org:ublue-os:staging \
        gnome-shell && \
    dnf5 -y upgrade --repo tayler \
        gnome-control-center \
        gnome-control-center-filesystem \
        mutter \
        mutter-common && \
    dnf5 -y install \
        gnome-randr-rust \
        gnome-epub-thumbnailer \
        gnome-tweaks \
        gnome-shell-extension-blur-my-shell \
        gnome-shell-extension-caffeine \
        gnome-shell-extension-just-perfection \
        gnome-shell-extension-hotedge && \
    dnf5 -y remove \
        gnome-tour \
        gnome-extensions-app \
        gnome-classic-session \
        gnome-shell-extension-background-logo \
        gnome-shell-extension-apps-menu && \
    dnf5 -y upgrade --repo copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control && \
    cpm enable vulongm/vk-hdr-layer && \
    dnf5 -y install \
        vk-hdr-layer && \
    sed -i '/^PRETTY_NAME/s/Silverblue/Quark/' /usr/lib/os-release && \
    sed -i 's/^NAME=.*/NAME="Quark"/' /usr/lib/os-release && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit \
    ; elif [[ "${BASE_IMAGE_NAME}" == "kinoite" ]]; then \
    dnf5 -y install \
        qt \
        ptyxis \
        kdeplasma-addons && \
    dnf5 -y remove \
        plasma-welcome \
        plasma-welcome-fedora && \
    dnf5 -y upgrade --repo tayler \
        qt6-qtbase && \
    sed -i '/^PRETTY_NAME/s/Kinoite/Quark Plasma/' /usr/lib/os-release && \
    sed -i 's/^NAME=.*/NAME="Quark Plasma"/' /usr/lib/os-release \
    ; fi

# Gaming-specific changes
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    if [[ "${IMAGE_NAME}" != *"quark-cloud-dev"* ]]; then \
    dnf5 -y install $(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases | jq -r '.[0].assets[] | select(.name | test("lact-libadwaita.*42.rpm")) | .browser_download_url') && \
    dnf5 -y install \
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
        steam \
        wine-core.x86_64 \
        wine-core.i686 \
        wine-pulseaudio.x86_64 \
        wine-pulseaudio.i686 \
        libFAudio.x86_64 \
        libFAudio.i686 \
        winetricks \
        mesa-vulkan-drivers.i686 \
        mesa-va-drivers.i686 \
        gamescope \
        gamescope-session-steam \
        vkBasalt.x86_64 \
        vkBasalt.i686 \
        mangohud.x86_64 \
        mangohud.i686 \
        protontricks \
        intel-undervolt && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/yad-icon-browser.desktop && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/winetricks.desktop && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/protontricks.desktop && \
    systemctl enable lactd && \
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
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
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
RUN curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/bin/kind && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install awscli
RUN curl -SL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/bin --install-dir /usr/bin && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

RUN echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo && rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    dnf5 -y install \
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
    sed -i '/^NAME/s/Quark/Quark Cloud Dev/' /usr/lib/os-release && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit
