# VM boot test inputs

The T2 check boots the shipped initrd in QEMU's `virt` machine, on the
J713 kernel. `j713-vm.config` is the production J713 configuration plus
`qemu-virt.config`, generated from `pkgs/linux/config/*.config`:

```sh
pkgs/linux/make-config.sh /path/to/gravity-linux \
  pkgs/linux/j713.config LLVM=1
pkgs/linux/make-config.sh /path/to/gravity-linux \
  tests/vm/j713-vm.config --with tests/vm/qemu-virt.config LLVM=1
```

Run this on Linux with GNU coreutils: the script uses `realpath`, and the
kernel configuration needs the same LLVM toolchain the package builds
with. Regenerate both the production and VM configs after changing
`pkgs/linux/config/` or the Gravity revision, then boot the check once on
a machine with an aarch64 builder.
