ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-fedora-$BASE_IMAGE_NAME}"
ARG BASE_IMAGE="quay.io/fedora/${SOURCE_IMAGE}"
ARG KERNEL_NAME="${KERNEL_NAME:-kernel-cachyos}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-43}"

FROM scratch AS ctx
COPY build_files /

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS quark

ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_NAME="${IMAGE_NAME:-quark}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG KERNEL_NAME="${KERNEL_NAME:-kernel-cachyos}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-43}"

COPY system_files /

# Update packages
RUN dnf5 -y upgrade

# Setup repos and ublue-os config rpms
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    curl -Lo /usr/bin/cpm https://github.com/trgeiger/cpm/releases/download/v1.0.3/cpm && chmod +x /usr/bin/cpm && \
    cpm enable \
        kylegospo/bazzite \
        ublue-os/staging \
        bieszczaders/kernel-cachyos \
        bieszczaders/kernel-cachyos-addons && \
    # if [[ "${FEDORA_MAJOR_VERSION}" == "43" ]]; then \
    #     dnf5 -y config-manager setopt "*fedora*".exclude="gdk-pixbuf2-*" \
    # ; fi && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
        # /tmp/rpms/config/*.rpm \
        fedora-repos-archive && \
    /ctx/cleanup

# Install CachyOS kernel
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-tools kernel-tools-libs kernel-uki-virt && \
    dnf5 -y install \
        "${KERNEL_NAME}"-modules && \
    dnf5 -y install \
        "${KERNEL_NAME}" \
        "${KERNEL_NAME}"-core \
        "${KERNEL_NAME}"-devel \
        "${KERNEL_NAME}"-devel-matched && \
    /ctx/cleanup

# Removals
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    dnf5 -y remove \
        google-noto-sans-cjk-vf-fonts \
        mesa-va-drivers \
        default-fonts-cjk-sans \
        firefox \
        firefox-langpacks && \
    /ctx/cleanup

# Additions and swaps
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
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
        koji-tool \
        libheif \
        libratbag-ratbagd \
        libva \
        libva-intel-media-driver \
        lshw \
        mesa-libGLU \
        mpv \
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
        xdg-user-dirs \
        xdg-terminal-exec \
        xrandr \
        zsh \
        zstd && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/mpv.desktop && \
    /ctx/cleanup

# Desktop environment stuff
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    if [[ "${BASE_IMAGE_NAME}" == "silverblue" ]]; then \
    dnf5 -y upgrade --repo copr:copr.fedorainfracloud.org:ublue-os:staging \
        gnome-shell && \
    # dnf5 -y upgrade --repo tayler \
        #gnome-control-center \
        #gnome-control-center-filesystem \
        # mutter \
        # mutter-common && \
    dnf5 -y install \
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
    # dnf5 -y upgrade --repo copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        # switcheroo-control && \
    sed -i '/^PRETTY_NAME/s/Silverblue/Quark/' /usr/lib/os-release && \
    sed -i 's/^NAME=.*/NAME="Quark"/' /usr/lib/os-release && \
    /ctx/cleanup \
    ; elif [[ "${BASE_IMAGE_NAME}" == "kinoite" ]]; then \
    dnf5 -y install \
        qt \
        ptyxis \
        kdeplasma-addons && \
    dnf5 -y remove \
        plasma-welcome \
        plasma-welcome-fedora && \
    # dnf5 -y upgrade --repo tayler \
        # kwin && \
    sed -i '/^PRETTY_NAME/s/Kinoite/Quark Plasma/' /usr/lib/os-release && \
    sed -i 's/^NAME=.*/NAME="Quark Plasma"/' /usr/lib/os-release \
    ; fi

# Gaming-specific changes
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    if [[ "${IMAGE_NAME}" != *"quark-cloud-dev"* ]]; then \
    dnf5 -y install \
        $(timeout 30 curl -s "https://api.github.com/repos/PancakeTAS/lsfg-vk/releases/latest" | grep "browser_download_url" | grep "lsfg-vk.*x86_64\.rpm" | cut -d '"' -f 4 || echo "") && \
    dnf5 -y install \
        gamescope \
        gamescope-session-steam \
        dbus-x11 \
        libFAudio.x86_64 \
        libFAudio.i686 \
        mangohud \
        protontricks \
        intel-undervolt \
        VK_hdr_layer && \
    dnf5 -y --setopt=install_weak_deps=False install \
        steam && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/protontricks.desktop && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/yad-icon-browser.desktop && \
    /ctx/cleanup \
    ; fi

# run post-install tasks and clean up
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    cpm disable \
        kylegospo/bazzite \
        ublue-os/staging \
        bieszczaders/kernel-cachyos \
        bieszczaders/kernel-cachyos-addons && \
    rm -f /etc/pki/akmods/private/private_key.priv && \
    rm -f /etc/pki/akmods/certs/public_key.der && \
    rm -f /usr/share/vulkan/icd.d/lvp_icd.*.json && \
    rm -f /usr/share/applications/htop.desktop && \
    rm -f /usr/share/applications/nvtop.desktop && \
    rm -f /usr/share/applications/shredder.desktop && \
    mkdir -p /usr/etc/flatpak/remotes.d && \
    curl -Lo /usr/etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    sed -i 's|^ExecStart=.*|ExecStart=/usr/libexec/rtkit-daemon --no-canary|' /usr/lib/systemd/system/rtkit-daemon.service && \
    sed -i 's@Name=tuned-gui@Name=TuneD Manager@g' /usr/share/applications/tuned-gui.desktop && \
    curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz" && \
    tar -xf /tmp/starship.tar.gz -C /tmp && \
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
    /ctx/image-info && \
    /ctx/build-initramfs && \
    /ctx/cleanup && \
    /ctx/finalize 


# cloud development build
FROM quark as quark-cloud-dev

ARG IMAGE_NAME="${IMAGE_NAME:-quark-cloud-dev}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

# Install Openshift tools -- oc, opm, kubectl, operator-sdk, odo, helm, crc
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    export VER=$(curl --silent -qI https://github.com/operator-framework/operator-sdk/releases/latest | \
    awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}') && \
    curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl && \
    curl -Lo /usr/bin/operator-sdk https://github.com/operator-framework/operator-sdk/releases/download/$VER/operator-sdk_linux_amd64 && \
    chmod +x /usr/bin/operator-sdk && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/opm-linux.tar.gz | tar xvzf - -C /usr/bin && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 -o /usr/bin/helm && chmod +x /usr/bin/helm && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/odo/latest/odo-linux-amd64 -o /usr/bin/odo && chmod +x /usr/bin/odo && \
    curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/crc/latest/crc-linux-amd64.tar.xz | tar xfJ - --strip-components 1 -C /usr/bin --wildcards '*/crc' && \
    /ctx/cleanup


# Install Kind
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/bin/kind && \
    /ctx/cleanup

# Install awscli
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    curl -SL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/bin --install-dir /usr/bin && \
    /ctx/cleanup

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo && rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    dnf5 -y install \
        code \
        make \
        qemu \
        libvirt \
        virt-manager && \
        rm -f /var/lib/unbound/root.key && \
    /ctx/cleanup

RUN echo -e "[google-cloud-cli]\nname=Google Cloud CLI\nbaseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=0\ngpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" > /etc/yum.repos.d/google-cloud-sdk.repo && \
    dnf5 -y install \
        libxcrypt-compat.x86_64 \
        google-cloud-cli \
        nodejs-npm
    

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    cpm remove --all && \
    rm -f get_helm.sh && \
    rm -rf aws && \
    rm -f awscliv2.zip && \
    rm -f /usr/bin/README.md && \
    rm -f /usr/bin/LICENSE && \
    sed -i '/^PRETTY_NAME/s/Quark/Quark Cloud Dev/' /usr/lib/os-release && \
    sed -i '/^NAME/s/Quark/Quark Cloud Dev/' /usr/lib/os-release && \
    /ctx/cleanup
