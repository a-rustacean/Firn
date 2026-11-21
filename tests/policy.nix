{ pkgs, nixos }:
let
  inherit (pkgs) lib;
  cfg = nixos.config;
  kernel = cfg.boot.kernelPackages.kernel;
  params = cfg.boot.kernelParams;
  login = cfg.services.logind.settings.Login;
  sleep = cfg.systemd.sleep.settings.Sleep;

  rules = {
    "devicetree matches the selected board" =
      cfg.hardware.deviceTree.filter == "t8132-${cfg.hardware.firn.board}.dtb";
    "the Mac mini has both on-board Ethernet drivers" =
      cfg.hardware.firn.board != "j773g"
      || (kernel.config.CONFIG_TIGON3 or "n") == "m" && (kernel.config.CONFIG_AQTION or "n") == "m";
    "kernel is this repository's Gravity source build" = kernel.modDirVersion == "7.3.0-firn";
    "the kernel builds no speaker codec driver" =
      lib.all
        (
          option:
          !(lib.elem (kernel.config."CONFIG_${option}" or "n") [
            "y"
            "m"
          ])
        )
        [
          "SND_SOC_TAS2764"
          "SND_SOC_TAS2770"
          "SND_SOC_APPLE_MCA"
          "SND_SOC_CS42L84"
        ];
    "no out-of-tree modules" = cfg.boot.extraModulePackages == [ ];
    "no kernel patches from the configuration" = cfg.boot.kernelPatches == [ ];
    "no devicetree overlays" = cfg.hardware.deviceTree.overlays == [ ];
    "nvme-apple's delayed flush is off (#167)" = lib.elem "nvme_apple.flush_interval=0" params;
    "kernel parameters do not set init=" = !(lib.any (lib.hasPrefix "init=") params);
    "suspend and hibernate are off" =
      sleep.AllowSuspend == "no"
      && sleep.AllowHibernation == "no"
      && sleep.AllowHybridSleep == "no"
      && sleep.AllowSuspendThenHibernate == "no";
    "closing the lid powers off" =
      login.HandleLidSwitch == "poweroff" && login.HandleLidSwitchExternalPower == "poweroff";
    "initrd is gzip, as the installer requires" = cfg.boot.initrd.compressor == "gzip";
    "boot.bin is written by firn-boot" =
      cfg.boot.loader.external.enable && !cfg.boot.loader.grub.enable;
    "no audio server is enabled" =
      !cfg.services.pipewire.enable && !(cfg.services.pulseaudio.enable or false);
    "the GPU driver is built" = (kernel.config.CONFIG_DRM_ASAHI or "n") == "m";
    "experimental memory/fabric voting is off" = lib.elem "apple_pmp_report.cpu_vote=0" params;
    "graphics are on, with Firn's Mesa" =
      cfg.hardware.graphics.enable && cfg.hardware.graphics.package == cfg.hardware.firn.mesa;
  };
  failed = lib.attrNames (lib.filterAttrs (_: ok: !ok) rules);
in
pkgs.runCommand "firn-policy" { } (
  if failed == [ ] then
    ''
      cat > $out <<'EOF'
      ${lib.concatMapStrings (r: "ok: ${r}\n") (lib.attrNames rules)}
      EOF
    ''
  else
    throw "Firn policy violated:\n${lib.concatMapStrings (r: "  - ${r}\n") failed}"
)
