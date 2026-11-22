# Patch audit

Checked on 22 November 2026 against the Gravity revisions pinned in
[SOURCES.md](SOURCES.md). Each patch was checked with `git apply --check`
against checkouts at the pinned revisions, and the upstream trees were
searched for equivalent changes. A clean apply proves only that the patch
is not already present verbatim; the notes below record the gap that keeps
it necessary.

These are downstream patches, not upstream submissions. Original
authorship and sign-offs remain in commit `9b58444` and the patch files.

## Linux (`pkgs/linux/patches`)

| Patch | Carries | Needed | Why |
|---|---|---|---|
| `0001-dt-bindings-Retain-Firn-platform-and-GPU-schemas.patch` | DT bindings for the platform, firmware and fixed-host wiring | Yes, for `devicetree-schema` | Upstream bindings still omit the M4 PMU, SMC GPIO/hwmon, T8132 AGX, ATC PHY fixed-host and several other properties the Firn DTS uses. |
| `0002-platform-Retain-Firn-correctness-and-CPU-thermal-fixes.patch` | CPU/GPU thermal and correctness fixes | Yes | Upstream lacks the PMP fast-die CPU cap, T8132 PMU/cpuidle handling, PMP report export and the workqueue exports `asahi_m4` needs. It also carries the SMC GPIO, AIC FIQ and brcmfmac fixes. |
| `0003-drm-Retain-G16-thermal-controls-and-display-cadence.patch` | G16 thermal controls and display cadence | Yes | Upstream has no `vblank.c`, `g16_cooling.rs`, `g16_cadence.rs` or `rust/kernel/thermal.rs`. Without them the GPU has no cooling device or thermal limits, and display completion/vblank is incomplete. |
| `0004-arm64-dts-Retain-Firn-direct-m1n1-board-policy.patch` | Direct-m1n1 board policy for J713 and J773G | Yes | Upstream J713 enables camera/audio and uses `t8132-j71x-thermal.dtsi`. Firn needs loader-enabled GPU/PMP, external displays/audio/camera off, and its own J713/J773G thermal policy. |

## m1n1 (`pkgs/m1n1/patches`)

| Patch | Carries | Needed | Why |
|---|---|---|---|
| `stage1/0001-nvme-Leave-the-M4-s-ANS-stopped-without-a-PMGR-reset.patch` | Skip the T8132 ANS PMGR reset after sleep | Yes, on affected J713 units | Upstream still resets ANS unconditionally; some J713 units wedge at the logo. Linux's `apple-nvme` resets the stopped ANS itself. |
| `stage1/0002-firmware-Recognize-macOS-27.2-boot-firmware.patch` | Recognize `mBoot-20457.41.3` | Yes for 27.2 | Upstream `fw_versions` has no `V27_2` entry, so m1n1 reports the firmware as unknown to the kernel. |
| `stage2/0001-kboot-Reserve-the-trust-cache.patch` | Reserve iBoot's TrustCache range | Yes, on T8132 | Upstream does not add the reservation; the trust cache lies in usable RAM and Linux can allocate over it. |
| `stage2/0002-kboot_gpu-Boot-without-the-GPU-when-the-T8132-handof.patch` | Continue boot with the GPU disabled when the T8132 handoff fails | Yes | Upstream still returns the handoff error and stops the boot. |
| `stage2/0003-kboot-Reserve-the-MTP-firmware-for-Linux.patch` | Reserve MTP firmware segments for Linux | Yes, when MTP is used | Upstream does not reserve them; Linux resets the unlocked DART and loses iBoot's firmware mappings. |
| `stage2/0004-kboot-Merge-contiguous-ASC-firmware-segments.patch` | Merge contiguous ASC firmware segments | Yes | Upstream rounds each segment separately; the MTP's `__TEXT` and `__DATA` overlap after rounding. |
| `stage2/0005-kboot-Move-the-initrd-off-the-CTRR-range.patch` | Move the initrd out of the CTRR range | Yes, with a large `boot.bin` | Upstream now reserves the CTRR range but leaves the initrd inside it. Linux frees initrd pages after unpacking and then faults on the protected pages. |
| `stage2/0006-firmware-Recognize-macOS-27.2-boot-firmware.patch` | Recognize `mBoot-20457.41.3` in stage 2 | Yes for 27.2 | Stage 2 has its own firmware table; upstream has no `V27_2` entry. |
| `stage2/0007-kboot_gpu-Pass-the-T8132-GPU-s-temperature-sensors-t.patch` | Pass the T8132 GPU's MTR sensor mask | Yes | Upstream has no `apple,m4-sensor-mask` handoff; G16 firmware reads only the sensors the driver enables. |

## Installer (`pkgs/installer/patches`)

| Patch | Carries | Needed | Why |
|---|---|---|---|
| `0001-osinstall-Build-next_object-from-m1n1-payloads.patch` | Build `next_object` from m1n1 payloads | Yes | Upstream ships a prebuilt boot object. Firn boots Linux directly from m1n1 with kernel/DTB/initramfs payloads, and must append the collected firmware to the initramfs. |
| `0002-gravity_firmware.wifi-Skip-non-firmware-files-from-m.patch` | Skip non-firmware files in macOS Wi-Fi directories | Yes, for macOS 26 images | Upstream asserts on `TrustedSHAInformation.txt` and on the unknown `F` property in 4388 C0 modules. |
| `0004-Offer-macOS-27.2-boot-firmware-for-the-J713.patch` | Offer the 27.2 restore image and recovery fallback | Optional for the current 26.6.2 kit; required to offer 27.2 | Upstream lists only 26.6.2 and limits the missing-`RestoreBundlePath` fallback to it. |

## Mesa (`pkgs/mesa/opencl.patch`)

Needed. Nix's LLVM CMake config does not provide `LLVM_LIBRARY_DIR`, and
nixpkgs owns the OpenCL ICD, so Mesa must not install `rusticl.icd`. This
is nixpkgs' `opencl.patch` rebased onto Gravity Mesa, not a duplicate
hardware-driver change.

## Removed patches

The installer's J713-enablement and expert-mode minimum patches are gone
because Gravity implements both. The old 622-patch Linux reconstruction is
gone because Gravity supplies the drivers and board enablement; the four
patches above are the remaining delta.

## Re-auditing

From a clean checkout of the pinned tree:

```sh
for p in pkgs/linux/patches/*.patch; do
  git -C /path/to/gravity-linux apply --check "$PWD/$p" || echo "FAILED: $p"
done
```

Repeat with the m1n1, installer and Mesa trees. A patch that no longer
applies needs rebasing before the pins move; a patch whose feature has
appeared upstream should be dropped and the result validated on hardware.
