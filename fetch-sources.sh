#!/bin/sh
# Replace the bundled sdhci-pci sources with the ones for another kernel version.
# Usage: ./fetch-sources.sh 6.12.117   (default: the running kernel's base version)
set -e
V=${1:-$(uname -r | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/')}
B="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/mmc/host"
cd "$(dirname "$0")/dkms"
for f in sdhci-pci-core.c sdhci-pci-o2micro.c sdhci-pci-arasan.c sdhci-pci-dwc-mshc.c \
         sdhci-pci-gli.c sdhci-pci.h sdhci.h sdhci-cqhci.h cqhci.h; do
  curl -sfL "$B/$f?h=v$V" -o "$f.new" && mv "$f.new" "$f" || { echo "could not fetch $f for v$V" >&2; exit 1; }
done
curl -sfL "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/mmc/host/Makefile?h=v$V" \
  | grep -A2 '^sdhci-pci-y' 
echo "Sources now from v$V. Check the sdhci-pci-y list above matches dkms/Kbuild, then run ./install.sh"
