#!/bin/sh

set -oeux pipefail

RELEASE="$(rpm -E '%fedora.%_arch')"
MAJOR_VERSION="$(rpm -E '%fedora')"
IMAGE_NAME="${1:-quark-open}"
NVIDIA_VERSION="${2:-stable}"

cd /tmp
if [[ "${NVIDIA_VERSION}" == "beta" ]]; then
    echo "Installing beta driver"
    dnf5 -y config-manager addrepo --from-repofile=https://developer.download.nvidia.com/compute/cuda/repos/fedora${QUARK_VERSION}/x86_64/cuda-fedora${QUARK_VERSION}.repo
    if [[ "${IMAGE_NAME}" == "quark-open" ]]; then
        dnf5 -y install --allowerasing nvidia-open \
    ; else
        dnf5 -y install cuda-drivers \
    ; fi
#dnf5 -y install rpmfusion-nonfree-release-rawhide && \
# ENABLED_REPO=rpmfusion-nonfree-rawhide \
else \
    echo "Installing stable driver" && \
    ls -alR /tmp/akmods-rpms && \
    #dnf5 -y install --enable-repo="$ENABLED_REPO" \
    dnf5 -y install \
        xorg-x11-drv-nvidia-cuda \
        xorg-x11-drv-nvidia-cuda-libs \
        nvidia-vaapi-driver \
        libva-utils \
        vdpauinfo \
        libva-nvidia-driver \
        mesa-vulkan-drivers.i686 \
        /tmp/akmods-rpms/kmods/kmod-nvidia-*.rpm \
; fi 