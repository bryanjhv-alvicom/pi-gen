FROM --platform=linux/arm/v7 debian

RUN export DEBIAN_FRONTEND=noninteractive\
 && apt update\
 && apt install -y apt-utils dialog\
 && apt install -y bc curl debootstrap dosfstools file git gpg kpartx libarchive-tools libcap2-bin parted pigz qemu-user-static qemu-utils quilt rsync xz-utils zerofree zip\
 && apt install -y fdisk kmod xxd\
 && rm -rf /var/lib/apt/lists/*
