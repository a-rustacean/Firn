{
  lib,
  fetchFromGitHub,
  linuxKernel,
  llvmPackages_21,
  buildPackages,
  # Needs /var/cache/ccache in nix.settings.extra-sandbox-paths.
  useCcache ? false,
  kernelPatches ? [ ],
  randstructSeed ? "",
  features ? { },
  # Shared J713/J773G config; legacy filename, generated from config/.
  configfile ? ./j713.config,
}:
(linuxKernel.manualConfig {
  inherit randstructSeed features configfile;
  version = "7.3.0";
  # Must match CONFIG_LOCALVERSION.
  modDirVersion = "7.3.0-firn";

  # Latest Gravity integration/apple-silicon-7.3-20261119-526 snapshot.
  src = fetchFromGitHub {
    owner = "GravityLinux";
    repo = "linux";
    rev = "c7e7b86aed0c4c052851e5c3b2c02088c0602f02";
    hash = "sha256-c+fOJqeqqwiHs9Cdz0RVZ/nReLgh0VEF3iEbGuq6o4E=";
  };

  # Shared T8132 support and board-local J713/J773G enablement.
  kernelPatches =
    map (name: {
      inherit name;
      patch = ./patches + "/${name}";
    }) (lib.attrNames (builtins.readDir ./patches))
    ++ kernelPatches;

  allowImportFromDerivation = true;

  stdenv = llvmPackages_21.stdenv;
  extraMakeFlags = [
    "LLVM=1"
    # From 7.3, LLVM=1 links host tools with lld; nixpkgs' host compiler is GCC.
    "HOSTLDFLAGS=-fuse-ld=bfd"
  ]
  # Overrides the unwrapped clang the kernel build sets.
  ++ lib.optional useCcache "CC=${lib.getExe buildPackages.ccache} ${lib.getExe llvmPackages_21.stdenv.cc.cc}";

  extraMeta.platforms = [ "aarch64-linux" ];
}).overrideAttrs
  (
    old:
    {
      # m1n1 boots Image.gz.
      buildFlags = map (flag: if flag == "Image" then "Image.gz" else flag) old.buildFlags;
      installTargets = [ "zinstall" ];
    }
    // lib.optionalAttrs useCcache {
      # Structured attributes export only env.
      env = (old.env or { }) // {
        CCACHE_DIR = "/var/cache/ccache";
        CCACHE_UMASK = "007";
        CCACHE_SLOPPINESS = "include_file_mtime,include_file_ctime,time_macros";
      };
    }
  )
