#!/bin/sh

set -oeux pipefail

RELEASE="$(rpm -E '%fedora.%_arch')"
MAJOR_VERSION="$(rpm -E '%fedora')"
IMAGE_NAME="${1:-quark-open}"
NVIDIA_VERSION="${2:-stable}"
USE_PERSONAL_REPO="${3:-false}"
ENABLED_REPO=""

cd /tmp
if [[ "${NVIDIA_VERSION}" == "beta" ]]; then
    echo "Installing beta driver\n"
    if [[ "${USE_PERSONAL_REPO}" == "true" ]]; then
        echo "Installing from personal repo\n"
        curl -Lo /etc/yum.repos.d/tayler-nvidia.repo https://raw.githubusercontent.com/trgeiger/nvidia-kmod-cache/refs/heads/main/tayler-nvidia.repo
    else
        echo "Installing from kwizart repo\n"
        dnf5 -y copr enable kwizart/nvidia-driver-rawhide
        sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/fedora-updates-testing.repo
        # Install fake-grubby for beta until f42
        dnf5 -y install rpmfusion-nonfree-release-rawhide
        ENABLED_REPO="rpmfusion-nonfree-rawhide"
    fi
else
    echo "Installing stable driver\n"
fi

ls -alR /tmp/akmods-rpms
dnf5 -y copr enable @ai-ml/nvidia-container-toolkit
dnf5 -y install --enable-repo="$ENABLED_REPO" \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    xorg-x11-drv-nvidia-cuda-libs \
    xorg-x11-drv-nvidia-power \
    nvidia-vaapi-driver \
    nvidia-container-toolkit \
    nvidia-container-toolkit-selinux \
    libva-utils \
    vdpauinfo \
    libva-nvidia-driver \
    mesa-vulkan-drivers.i686 \
    /tmp/akmods-rpms/kmods/kmod-nvidia-*.rpm

