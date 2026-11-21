# Firn

NixOS on the 13-inch M4 MacBook Air (Mac16,12 / J713) and M4 Mac mini
(Mac16,10 / J773G). Experimental and unofficial.

Everything that runs on the Air is built from source here:

- the kernel: Gravity Linux's latest integration, with Firn's remaining
  boot, safety and thermal changes;
- m1n1 stage 1 and stage 2: Gravity Linux's bootloader with Firn's patches;
- Mesa: Gravity Linux's, whose asahi drivers support the M4's GPU;
- the macOS-side installer: Gravity Linux's J713/J773G installer branch,
  with Firn's boot-payload format.

Exact source revisions and remaining patches are listed in [docs/SOURCES.md](docs/SOURCES.md).

The installer runs under python.org's Python for macOS and Homebrew's libffi,
both pinned by hash, as Asahi Linux's own installer does.

## What works

On the Air: keyboard, trackpad, NVMe, Wi-Fi, Bluetooth, the power management
coprocessor (PMP), the internal display through its display controller
(DCP), with brightness and blanking, and the GPU: OpenGL, OpenGL ES,
Vulkan and OpenCL through Gravity Linux's Mesa
([docs/GPU.md](docs/GPU.md)). Thermal zones throttle the CPUs and the
GPU. Set `hardware.firn.wifiRegion` (for example `"US"`) for 5 GHz Wi-Fi.

USB-C is built but not yet tested ([docs/TODO.md](docs/TODO.md)).

The mini adds GravityLinux-derived HDMI, all five USB ports (the front pair
share a hub), on-board Ethernet, radio firmware selection and GPU/PMP handoff.
Installation and boot have been reported working on J773G. Audio, USB4 and
USB-C displays remain disabled; the Air's support is unchanged.

Not supported: speakers, headphones, external displays, suspend. Closing the lid powers off. Sustained writes of
several GB can crash the storage controller; see
[docs/ISSUES.md](docs/ISSUES.md).

## Layout

| Path | What |
|---|---|
| `modules/` | The NixOS module: kernel, boot, firmware, power, graphics, root image |
| `pkgs/linux/` | The kernel and devicetree: configuration, patch series, module list |
| `pkgs/m1n1/` | m1n1 stage 1 and stage 2 |
| `pkgs/mesa/` | Mesa, for the GPU |
| `pkgs/installer/` | The macOS-side installer |
| `pkgs/firn-boot/` | Writes each generation into `boot.bin`, with tests |
| `pkgs/firn-report/` | A read-only hardware report |
| `pkgs/kit/` | The installer kit: installer, OS package and guide |
| `tests/` | Policy checks, kernel module list, devicetree schema, VM boot |
| `examples/minimal/` | A console-only system, with graphics for GPU work |

## Booting

The installer registers m1n1 stage 1 in a small macOS stub, which loads
`<ESP>/m1n1/boot.bin`: m1n1 stage 2, kernel parameters, kernel, devicetree,
and an initrd with the Apple firmware the installer collected. Every
`nixos-rebuild boot|switch` runs [`firn-boot`](pkgs/firn-boot/firn-boot.py),
which writes the generation's m1n1, kernel, devicetree, initrd and parameters
in the same layout and keeps the firmware. It accepts J713 and J773G and
refuses to switch the installed board's devicetree.
The installer's file is kept as `boot.bin.original`, the last one as `boot.bin.previous`.
The installer's other files on that partition move to
`/var/lib/firn/installer/`, to leave room for them.

## Building

The kernel and m1n1 cross-compile on x86_64:

```
nix build .#packages.x86_64-linux.linux
nix build .#checks.x86_64-linux.policy .#checks.x86_64-linux.kernel-modules
```

Both boards use the same kernel. Select `hardware.firn.board = "j713"` or
`"j773g"`; the default remains J713 for existing configurations.

| Board | NixOS configuration | Installer kit package |
|---|---|---|
| J713 | `.#j713` | `.#packages.x86_64-linux.kit-j713` |
| J773G | `.#j773g` | `.#packages.x86_64-linux.kit-j773g` |

The existing `minimal` and `kit` names remain aliases for J713.

The rest of the system needs an aarch64 builder, or
`boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` on the build machine.
Mesa is the one large build, and slow under emulation: build
`.#packages.aarch64-linux.mesa` on an aarch64 machine, the Air itself
included, and copy it back.
[docs/RUNBOOK.md](docs/RUNBOOK.md) lists the test tiers;
[docs/GUIDE.md](docs/GUIDE.md) is the install guide, also shipped in the kit.
Machine-local settings such as SSH keys go in `examples/minimal/access.nix`,
which is gitignored and imported when present. A flake reference to the
git tree leaves untracked files out, so build the system with
`path:.#minimal` to include it.

## Provenance

The former exported kernel series, its authors and imported sign-offs are
preserved in commit `9b58444`. The Gravity-based downstream delta and its
provenance are described in [docs/SOURCES.md](docs/SOURCES.md). Changes from
[Omarchy-M4-Native](https://github.com/Kb2uka/Omarchy-M4-Native) retain their
credits in that history and in m1n1's patches.
Some imported commits, most of them in the GPU series from Gravity Linux,
do not yet carry their authors' `Signed-off-by`; they are listed in
[docs/TODO.md](docs/TODO.md) and are not ready to send upstream until
their authors sign them off.
The installer patches credit the Gravity Linux installer, as shipped by
Omarchy-M4-Native, where they follow it. The installer kit ships the
licence notices of everything in the installer. The logo
([artwork/firn-logo.png](artwork/firn-logo.png)) is derived from Gravity
Linux's.

## Licence

Firn's own code is under the [MIT licence](LICENSE). Patches keep the
licence of the project they apply to: GPL-2.0 for the kernel, and m1n1's
and the installer's own licences for theirs.

Firn is not affiliated with or endorsed by Asahi Linux, Omarchy-M4-Native,
Gravity Linux or Apple.
