#!/usr/bin/bash

set -eoux pipefail

KERNEL_NAME="${1}"

echo "::group::Executing install-kernel for ${KERNEL_NAME}"
trap 'echo "::endgroup::"' EXIT

# create a shims to bypass kernel install triggering dracut/rpm-ostree
# seems to be minimal impact, but allows progress on build
pushd /usr/lib/kernel/install.d
mv 05-rpmostree.install 05-rpmostree.install.bak
mv 50-dracut.install 50-dracut.install.bak
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x  05-rpmostree.install 50-dracut.install
popd

# Remove Existing Kernel
for pkg in kernel kernel{-core,-modules,-modules-core,-modules-extra,-tools-libs,-tools}; do
    rpm --erase "${pkg}" --nodeps
done

# cleanup leftovers that are not covered by kernel-* packages for some reason
rm -rf /usr/lib/modules

dnf5 -y install \
    "${KERNEL_NAME}"-modules

dnf5 -y install \
    "${KERNEL_NAME}" \
    "${KERNEL_NAME}"-core \
    "${KERNEL_NAME}"-devel \
    "${KERNEL_NAME}"-devel-matched

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules

pushd /usr/lib/kernel/install.d
mv -f 05-rpmostree.install.bak 05-rpmostree.install
mv -f 50-dracut.install.bak 50-dracut.install
popd
