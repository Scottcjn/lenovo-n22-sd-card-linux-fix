#!/bin/sh
set -e
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
dkms remove n22-sdhci-pci/1.0 --all || true
rm -rf /usr/src/n22-sdhci-pci-1.0
depmod -a
echo "Removed. Reboot to return to the stock sdhci-pci driver."
