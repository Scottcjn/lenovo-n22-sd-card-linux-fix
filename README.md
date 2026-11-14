# Lenovo N22 SD card reader fix for Linux (Celeron N3050 / Braswell, PCI 8086:2296)

The SD card slot on the **Lenovo N22 Chromebook-style Windows laptop (model 80S6, Intel Celeron N3050 "Braswell")** has not worked on Linux since around kernel 4.14. This repo installs a patched `sdhci-pci` kernel module with **DKMS** so the slot works again and keeps working after kernel updates.

Tested and working on: **Lenovo N22 80S6, Celeron N3050, Debian 13 (trixie), kernel 6.12.117+deb13-amd64**, 64 GB SDXC card detected as `mmc2: new ultra high speed SDR104 SDXC card`.

## Symptoms this fixes
- An SD/microSD card is inserted, but **nothing appears** in `lsblk`, Files or `dmesg`.
- `dmesg` repeats this line many times and never shows a `mmcN: SDHCI controller on PCI` line:
  ```
  sdhci-pci 0000:00:12.0: SDHCI controller found [8086:2296] (rev 21)
  ```
- `dmesg` may also show:
  ```
  mmc0: SDHCI controller on ACPI [INT33BB:00] using ADMA
  mmc0: Failed to initialize a non-removable card
  ```
- `/sys/kernel/debug/devices_deferred` lists `0000:00:12.0` (the PCI SD controller is stuck in deferred probe).
- `/sys/bus/pci/devices/0000:00:12.0/driver` does not exist (no driver bound).

## Cause
The firmware exposes the Braswell SD controller twice: as PCI device `0000:00:12.0` (`8086:2296`) and as ACPI node `INT33BB:00` (`\_SB_.PCI0.SDHB`). The PCI driver asks for a card-detect GPIO that never becomes available on this machine, so it defers forever. Its aggressive runtime power management also misbehaves on this board.

## The fix (credit)
The patches are by **Nelson Johnson**, posted to the Linux kernel mailing list on 2026-03-16: [[PATCH 0/3] mmc: Lenovo N22 Braswell SD slot fixes](https://lkml.iu.edu/hypermail/linux/kernel/2603.2/01944.html). This repo only packages them for DKMS. All credit for the diagnosis goes to him.

| Patch | Used here | What it does |
|---|---|---|
| [1/3](https://lkml.iu.edu/hypermail/linux/kernel/2603.2/01924.html) disable aggressive runtime PM | yes | No `MMC_CAP_AGGRESSIVE_PM` / `MMC_CAP_CD_WAKE`, runtime PM off for this slot |
| [2/3](https://lkml.iu.edu/2603.2/01926.html) force polling card detect | yes | `cd_idx = -1` (skip the broken GPIO) + `MMC_CAP_NEEDS_POLL` |
| 3/3 exclude `INT33BB:00` from sdhci-acpi | **no** | Not needed in testing ([a tester reported the same](https://lkml.iu.edu/2603.2/11021.html)). Leaving `sdhci-acpi` untouched also keeps the **eMMC boot disk** safe, because the same driver runs it. |

Both patches only take effect when DMI reports `sys_vendor=LENOVO` and `board_name=N22`. On any other machine the module behaves like the stock driver. The installer refuses to run on other machines anyway.

## Install (Debian / Ubuntu)
```
git clone https://github.com/Scottcjn/lenovo-n22-sd-card-linux-fix
cd lenovo-n22-sd-card-linux-fix
sudo ./install.sh
```
The script:
1. Checks the machine is a Lenovo N22.
2. Installs `dkms`, `patch` and the headers for your running kernel.
3. Copies `dkms/` to `/usr/src/n22-sdhci-pci-1.0` and builds the module. The patches in `dkms/patches/` are applied to pristine kernel sources at build time.
4. Reloads `sdhci_pci`, so no reboot is needed.

Check it worked:
```
dmesg | grep mmc        # expect: mmcN: SDHCI controller on PCI [0000:00:12.0] using ADMA
lsblk                   # the card appears as /dev/mmcblkN
```

**Secure Boot:** if Secure Boot is on, DKMS signs the module with a MOK key that you must enroll (`mokutil --import /var/lib/dkms/mok.pub`, then reboot and follow the blue screen). With Secure Boot off, it loads directly. A `module verification failed ... tainting kernel` message is normal for any out-of-tree module.

## Other kernel versions
The bundled sources are from **Linux stable v6.12.117** (Debian 13's kernel series). For a different kernel series, fetch the matching sources first:
```
./fetch-sources.sh            # uses your running kernel's version
./fetch-sources.sh 6.19.6     # or a specific one
sudo ./install.sh
```
If a patch no longer applies, the build stops with `patch failed:` instead of installing a broken module.

## Uninstall
```
sudo ./uninstall.sh && sudo reboot
```

## Status
- Tested on **one** N22 unit (Debian 13, 6.12.117). Card detected at SDR104, ext4 card mounted and auto-mounting from `/etc/fstab`.
- Hot-swap: card removal and re-insertion are detected within about 1 second (`mmc2: card aaaa removed` / `new ... SDXC card`).
- Tip: pulling a card while it is mounted is like yanking a USB stick (`EXT4-fs ... I/O error`). For a card you swap often, add `x-systemd.automount,nofail` to its `/etc/fstab` line: it then mounts on first access after you re-insert it, and systemd unmounts it when the card is removed.
- Not yet tested: suspend/resume with a card inserted, Ubuntu kernels, other Braswell laptops (N23, 100S, etc.). Reports are welcome as issues.
- When the upstream patches land in mainline and your distro kernel, uninstall this. You won't need it anymore.

## Keywords
Lenovo N22 SD card not working Linux; Lenovo N22 80S6 card reader Debian; Celeron N3050 SD card slot not detected; Braswell SDHCI 8086:2296 no card; sdhci-pci deferred probe; INT33BB; SD card reader not recognized Ubuntu Lenovo N22; Lenovo N22 microSD Linux fix.

## License
GPL-2.0, same as the Linux kernel sources and patches it contains (see the SPDX headers in each file and `LICENSE`).
