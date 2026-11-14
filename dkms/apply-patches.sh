#!/bin/sh
# Runs in the DKMS build dir: apply the N22 patches to the pristine kernel sources.
set -e
for p in patches/*.patch; do
  patch -p4 --forward --silent < "$p" || { echo "patch failed: $p" >&2; exit 1; }
done
grep -q sdhci_pci_is_lenovo_n22_bsw_sd sdhci-pci-core.c
