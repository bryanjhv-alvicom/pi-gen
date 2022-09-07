#!/bin/bash -e

install -m 644 files/tailscale.gpg "${ROOTFS_DIR}/etc/apt/trusted.gpg.d/"
install -m 644 files/tailscale.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"
on_chroot << EOF
apt-get update
EOF
