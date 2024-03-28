# Quark

[![build-quark](https://github.com/trgeiger/quark/actions/workflows/build.yml/badge.svg)](https://github.com/trgeiger/quark/actions/workflows/build.yml)

Silverblue customized with my personal base image preferences.

## Usage
To rebase to either Quark or Quark Cloud Dev:
```console
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/trgeiger/quark:latest
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/trgeiger/quark-cloud-dev:latest
```

The `latest` tag will automatically point to the latest build. 