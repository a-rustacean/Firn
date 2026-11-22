# Gravity source snapshots

Checked against Gravity Linux on 21 November 2026. Sources stay pinned by
commit and hash; builds never follow a moving branch implicitly.

| Component | Gravity repository / branch | Commit |
|---|---|---|
| Linux 7.3 | `linux`, `integration/apple-silicon-7.3-20261119-526` | `c7e7b86aed0c4c052851e5c3b2c02088c0602f02` |
| m1n1 | `bootloader`, `main` | `ac17c97fc15c91fcdfd6009f5788f808558fe26f` |
| Installer | `installer`, `air-j713` | `f54140ea4957363c6fcdd8f1699b2e38730603ab` |
| Mesa | `mesa`, `main` | `f66f380c648551249df5ba8538983279ca800985` |

The dated kernel integration is newer than the repository's default
integration branch. The installer branch supports both J713 and J773G,
including their separate radio firmware profiles. Mesa was already current.

## Downstream changes

The per-patch audit is in [PATCHES.md](PATCHES.md): what each patch
carries, whether it is still needed, and why.

The old 622-patch reconstruction of mainline Linux is replaced by Gravity's
tree and four patches containing the remaining Firn delta:

- Binding coverage for the actual platform, firmware and fixed-host wiring.
- Correctness fixes, CPU PMU support, PMP register replies and CPU thermal
  limiting, plus the workqueue exports needed by Gravity's modular GPU build.
- GPU fuse-derived sensor selection, performance limits, cooling-device
  registration, firmware timing and display/fence cadence.
- Direct-m1n1 board policy: firmware-backed devices start disabled; audio,
  camera and external USB-C displays remain off. J713 retains its CPU/GPU
  thermal policy; the mini does not inherit laptop limits. Gravity's new
  memory/fabric vote is disabled pending separate hardware qualification.

Drivers, PCIe/networking, USB fixed-host support, HDMI and board enablement
are now supplied by Gravity rather than exported again as local patches.
The former patches, their authors and imported sign-offs remain available
in commit `9b58444`. Rebasing is not a new author sign-off, and these
remaining patches are not ready for upstream submission without review.

The installer no longer needs Firn's J713-enablement or expert-minimum
patches: Gravity implements both. The payload-format extension, generic
macOS firmware-file filtering and optional 27.2 recovery support remain.
All nine m1n1 patches were checked against the new snapshot and still apply
(see [PATCHES.md](PATCHES.md)): ANS handling, memory reservations, GPU
fallback/sensors and 27.2 recognition have not been incorporated there.
Mesa's patch is Nix-specific library discovery, not a duplicate hardware
driver change.

Gravity's GPU configuration symbol is `DRM_ASAHI`; its M4 module remains
`asahi_m4`. The PMP report driver is now `apple_pmp_report`, including the
prefix of the boot parameter used to disable experimental voting.

Firn's NixOS modules, packaging and boot updater remain local. Ordinary
userspace dependencies still come from pinned nixpkgs; the macOS Python,
libffi and Apple restore-image inputs retain their existing upstream pins.

The first J773G kit (`9b58444`) has a user-reported successful installation
and boot. That result does not qualify these newer source revisions;
hardware validation is still required after the migration.
