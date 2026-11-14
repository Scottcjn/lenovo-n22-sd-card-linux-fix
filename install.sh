#!/bin/sh
# Install the Lenovo N22 SD-slot fix as a DKMS module (rebuilds on kernel updates).
set -e
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
board=$(cat /sys/class/dmi/id/board_name 2>/dev/null); vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
if [ "$vendor" != "LENOVO" ] || [ "$board" != "N22" ]; then
  echo "This machine reports '$vendor' / '$board', not LENOVO / N22."
  echo "The patch only changes behaviour on the N22 (DMI match), so it would do nothing here. Stopping."; exit 1
fi
lspci -nn 2>/dev/null | grep -q '8086:2296' || echo "warning: PCI 8086:2296 not listed by lspci (continuing)"
if command -v mokutil >/dev/null && mokutil --sb-state 2>/dev/null | grep -q enabled; then
  echo "NOTE: Secure Boot is ON. The module must be signed with an enrolled MOK key or it will not load."
fi
if command -v apt-get >/dev/null; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends dkms "linux-headers-$(uname -r)" patch
fi
SRC=/usr/src/n22-sdhci-pci-1.0
dkms remove n22-sdhci-pci/1.0 --all >/dev/null 2>&1 || true
rm -rf "$SRC"; cp -r "$(dirname "$0")/dkms" "$SRC"
dkms add n22-sdhci-pci/1.0
dkms install n22-sdhci-pci/1.0
modprobe -r sdhci_pci 2>/dev/null && modprobe sdhci_pci || echo "Could not reload sdhci_pci now; reboot to activate."
sleep 3
dmesg | grep -E 'mmc[0-9]+: (SDHCI controller on PCI|new .*card)' | tail -3
echo "Done. Insert a card; it should appear as /dev/mmcblkN within ~1 second (lsblk)."
