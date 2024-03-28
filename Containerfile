ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
# ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME}"
# ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/${SOURCE_IMAGE}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS quark

ARG IMAGE_NAME="${IMAGE_NAME:-quark}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"

COPY etc /etc
COPY usr /usr
COPY tmp /tmp
COPY rpms /tmp/rpms

# Add custom repos
RUN wget https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-$(rpm -E %fedora)/ublue-os-staging-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_ublue-os-staging.repo && \
    wget https://copr.fedorainfracloud.org/coprs/kylegospo/system76-scheduler/repo/fedora-$(rpm -E %fedora)/kylegospo-system76-scheduler-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_kylegospo-system76-scheduler.repo && \
    wget https://copr.fedorainfracloud.org/coprs/sentry/switcheroo-control_discrete/repo/fedora-$(rpm -E %fedora)/sentry-switcheroo-control_discrete-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_sentry-switcheroo-control_discrete.repo



# RUN rpm-ostree install \
#         https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
#         https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install CachyOS kernel
RUN wget https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos/repo/fedora-$(rpm -E %fedora)/bieszczaders-kernel-cachyos-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_cachyos_kernel.repo && \
    rpm-ostree cliwrap install-to-root / && \
    rpm-ostree override remove \
        kernel \
        kernel-core \
        kernel-modules \
        kernel-modules-core \
        kernel-modules-extra \
    --install \
        kernel-cachyos

# Update packages that commonly cause build issues
# RUN rpm-ostree override replace \
#     --experimental \
#     --from repo=fedora \
#         vim-data \
#         vim-minimal

# RUN rm -rf /etc/yum.repos.d/fedora-updates-testing.repo
RUN rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        vulkan-loader \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        alsa-lib \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        gnutls \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        glib2 \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        gtk3 \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        atk \
        at-spi2-atk \
        at-spi2-core \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        libaom \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        gstreamer1 \
        gstreamer1-plugins-base \
        gstreamer1-plugins-bad-free-libs \
        gstreamer1-plugins-good-qt \
        gstreamer1-plugins-good \
        gstreamer1-plugins-bad-free \
        gstreamer1-plugin-libav \
        gstreamer1-plugins-ugly-free \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        python3 \
        python3-libs \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        libdecor \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        libtirpc \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        libuuid \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        libblkid \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        libmount \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        cups-libs \
        || true && \
    rpm-ostree override remove \
        glibc32 \
        || true

# Removals
RUN rpm-ostree override remove \
        firefox \
        firefox-langpacks && \
    rpm-ostree override remove \
        power-profiles-daemon \
        || true

# Additions
RUN rpm-ostree install \
        bootc \
        zsh \
        mesa-vdpau-drivers-freeworld \
        zsh \
        tuned \
        tuned-ppd \
        tuned-utils \
        tuned-gtk \
        tuned-profiles-atomic \
        tuned-profiles-cpu-partitioning \
        powertop \
        input-remapper \
        jq \
        edid-decode \
        zsh \
        patch \
        python3-pip \
        libadwaita \
        duperemove \
        xrandr \
        system76-scheduler \
        unrar \
        setools \
        rsms-inter-fonts \
        jetbrains-mono-fonts \
        mesa-libGLU \
        vulkan-tools && \
    pip install --prefix=/usr topgrade && \
    rpm-ostree install \
        ublue-update && \
    sed -i '1s/^/[include]\npaths = ["\/etc\/ublue-os\/topgrade.toml"]\n\n/' /usr/share/ublue-update/topgrade-user.toml && \
    sed -i 's/min_battery_percent.*/min_battery_percent = 20.0/' /usr/etc/ublue-update/ublue-update.toml && \
    sed -i 's/max_cpu_load_percent.*/max_cpu_load_percent = 100.0/' /usr/etc/ublue-update/ublue-update.toml && \
    sed -i 's/max_mem_percent.*/max_mem_percent = 90.0/' /usr/etc/ublue-update/ublue-update.toml && \
    sed -i 's/dbus_notify.*/dbus_notify = false/' /usr/etc/ublue-update/ublue-update.toml && \
    # Install patched fonts from Terra then remove repo
    wget https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo -O /etc/yum.repos.d/terra.repo && \
    rpm-ostree install \
        cascadiacode-nerd-fonts \
        maple-fonts && \
    rm -rf /etc/yum.repos.d/terra.repo

# Gnome stuff
RUN rpm-ostree install \
        gnome-shell-extension-just-perfection \
        gnome-shell-extension-system76-scheduler && \
    rpm-ostree override remove \
        gnome-software-rpm-ostree \
        gnome-tour \
        gnome-classic-session \
        gnome-classic-session-xsession \
        gnome-terminal-nautilus \
        yelp && \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control && \
    # TODO set up copr for patched and additional packages
    rpm-ostree override replace \
        /tmp/rpms/override/*.rpm
    # rpm-ostree install \
        # /tmp/rpms/install/*.rpm

# Gaming-specific changes
RUN if [[ "${IMAGE_NAME}" == "quark" ]]; then \
    rpm-ostree install \
        glibc.i686 \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        audit-libs \
        glibc \
        glibc-common \
        glibc-gconv-extra \
        glibc-all-langpacks \
    --install \
        glibc.i686 \
        || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates-testing \
        audit-libs \
        || true && \
    rpm-ostree install \
        /tmp/rpms/install/*.rpm \
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
        clinfo \
        gamescope \
        vkBasalt \
        mangohud \
        steam \
        mesa-vulkan-drivers.i686 \
        mesa-va-drivers-freeworld.i686 && \
    rpm-ostree override remove \
        gamemode && \
    wget \
        $(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | \
        jq -r ".assets[] | select(.name | test(\"lact-libadwaita.*fedora\")) | .browser_download_url") \
        -O /tmp/rpms/lact.rpm && \
    rpm-ostree install \
        /tmp/rpms/lact.rpm && \
    systemctl enable lactd && \
    sed -i 's@/usr/bin/steam@/usr/bin/xtest-steam@g' /usr/share/applications/steam.desktop && \
    systemctl enable gamescope-workaround.service \
    ; fi

# run post-install tasks and clean up
RUN /tmp/image-info.sh && \
    rm -f /usr/share/vulkan/icd.d/lvp_icd.*.json && \
    rm -f /usr/share/applications/htop.desktop && \
    rm -f /usr/share/applications/nvtop.desktop && \
    rm -f /usr/share/applications/shredder.desktop && \
    rm -rf /etc/yum.repos.d/_copr* && \
    mkdir -p /usr/etc/flatpak/remotes.d && \
    wget -q https://dl.flathub.org/repo/flathub.flatpakrepo -P /usr/etc/flatpak/remotes.d && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/org.gnome.Terminal.desktop  && \
    sed -i 's@Name=tuned-gui@Name=TuneD Manager@g' /usr/share/applications/tuned-gui.desktop && \
    curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" && \
    tar -xzf /tmp/starship.tar.gz -C /tmp && \
    install -c -m 0755 /tmp/starship /usr/bin && \
    echo 'eval "$(starship init bash)"' >> /etc/bashrc && \
    echo 'eval "$(starship init zsh)"' >> /etc/zshrc && \
    systemctl enable com.system76.Scheduler.service && \
    systemctl enable tuned.service && \
    systemctl enable btrfs-dedup@var-home.timer && \
    systemctl enable input-remapper.service && \
    systemctl enable dconf-update.service && \
    systemctl unmask flatpak-manager.service && \
    systemctl enable flatpak-manager.service && \
    systemctl disable rpm-ostreed-automatic.timer && \
    systemctl enable ublue-update.timer && \
    systemctl --global enable podman.socket && \
    systemctl --global enable systemd-tmpfiles-setup.service && \
    echo "import \"/usr/share/ublue-os/just/80-quark.just\"" >> /usr/share/ublue-os/justfile && \
    sed -i '/^PRETTY_NAME/s/Silverblue/Quark/' /usr/lib/os-release && \
    rm -rf /tmp/* /var/* && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp && \
    ostree container commit


# cloud development build
FROM quark as quark-cloud-dev

ARG IMAGE_NAME="${IMAGE_NAME:-quark-cloud-dev}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

# Install Openshift tools -- oc, opm, kubectl, operator-sdk, odo, helm, crc
RUN export VER=$(curl --silent -qI https://github.com/operator-framework/operator-sdk/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}') && \
  wget https://github.com/operator-framework/operator-sdk/releases/download/$VER/operator-sdk_linux_amd64 -O /usr/bin/operator-sdk && \
  chmod +x /usr/bin/operator-sdk
RUN curl -SL https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz | tar xvzf - -C /usr/bin
RUN curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/opm-linux.tar.gz | tar xvzf - -C /usr/bin
RUN curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 -o /usr/bin/helm && chmod +x /usr/bin/helm
RUN curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/odo/latest/odo-linux-amd64 -o /usr/bin/odo && chmod +x /usr/bin/odo
RUN curl -SL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/crc/latest/crc-linux-amd64.tar.xz | tar xfJ - --strip-components 1 -C /usr/bin

# Install awscli
RUN curl -SL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/bin --install-dir /usr/bin

# VSCode repo
RUN echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo && rpm --import https://packages.microsoft.com/keys/microsoft.asc

RUN rpm-ostree install \
        code \
        qemu \
        libvirt \
        virt-manager && \
        rm -f /var/lib/unbound/root.key

RUN rm -f /etc/yum.repos.d/vscode.repo && \
    rm -f /usr/bin/xtest-steam && \
    rm -f /etc/yum.repos.d/_copr_* && \
    rm -f get_helm.sh && \
    rm -rf aws && \
    rm -f awscliv2.zip && \
    rm -f /usr/bin/README.md && \
    rm -f /usr/bin/LICENSE && \
    rm -rf /tmp/* /var/* && \
    sed -i '/^PRETTY_NAME/s/Quark/Quark Cloud Dev/' /usr/lib/os-release && \
    ostree container commit
