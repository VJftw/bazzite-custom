#!/bin/bash

# asus-x470-prime-pro: ASUS X470 Prime Pro desktop

set -ouex pipefail

# Fan control for the ASUS X470 Prime Pro (ITE IT8665E Super I/O)
# lm_sensors provides sensors/sensors-detect, liquidctl supports AIOs/USB controllers
dnf5 install -y lm_sensors liquidctl

# CoolerControl from COPR (daemon + GUI)
dnf5 -y copr enable codifryed/CoolerControl
dnf5 -y install coolercontrol coolercontrold
dnf5 -y copr disable codifryed/CoolerControl

# The in-kernel it87 driver does not support the IT8665E, so build the out-of-tree
# driver against the kernel installed in the image. depmod prefers extra/ over kernel/.
IT87_REF=bd7a566c8a60fe0308d67e26761e16260368191a
KVER="$(basename /usr/lib/modules/*)"
git clone https://github.com/frankcrawford/it87 /tmp/it87
git -C /tmp/it87 checkout "$IT87_REF"
make -C /tmp/it87 KERNEL_BUILD="/usr/lib/modules/${KVER}/build" TARGET="${KVER}"
install -Dm644 /tmp/it87/it87.ko "/usr/lib/modules/${KVER}/extra/it87.ko"
depmod -a "${KVER}"
rm -rf /tmp/it87

# Load the Super I/O hwmon driver at boot so motherboard fan headers are exposed
echo it87 > /etc/modules-load.d/it87.conf

systemctl enable coolercontrold.service
