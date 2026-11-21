#!/usr/bin/env bash
# Regenerate the downstream patches: one patch per commit of BRANCH
# on top of the Gravity commit BASE that default.nix fetches.
#   update-patches.sh KERNEL_CHECKOUT [BRANCH] [BASE]
set -euo pipefail

src=$1
branch=${2:-firn/next}
base=${3:-c7e7b86aed0c4c052851e5c3b2c02088c0602f02}
out=$(dirname "$(realpath "$0")")/patches

rm -rf "$out"
git -C "$src" format-patch -q -N --zero-commit --no-signature -o "$out" "$base..$branch"
