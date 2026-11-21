# dtbs_check and dt_binding_check; fails on any warning not listed below.
{
  pkgs,
  kernel,
}:
let
  inherit (pkgs) lib;
  patches = ../pkgs/linux/patches;
  src = pkgs.applyPatches {
    name = "linux-t8132-source";
    inherit (kernel) src;
    patches = map (name: patches + "/${name}") (lib.attrNames (builtins.readDir patches));
  };
  bindings = lib.concatStringsSep ":" [
    "apple,nvme-ans.yaml"
    "apple,dart.yaml"
    "apple,sart.yaml"
    "apple,spi.yaml"
    "apple,spmi.yaml"
    "apple,smc.yaml"
    "apple,smc-hwmon.yaml"
    "apple,pcie.yaml"
    "apple,dwc3.yaml"
    "apple,mailbox.yaml"
    "apple,agx.yaml"
    "apple,admac.yaml"
    "apple,cluster-cpufreq.yaml"
    "apple,sio.yaml"
    "apple,spmi-nvmem.yaml"
    "apple,atcphy.yaml"
    "apple,pinctrl.yaml"
    "apple,pmp.yaml"
    "apple,pmp-report.yaml"
    "ti,tps6598x.yaml"
  ];
  # Reviewed warnings in the pinned Gravity tree, including disabled camera,
  # audio and USB4 descriptions. Any change to this baseline still fails.
  expectedAir = ./devicetree-warnings/j713;
  expectedMini = ./devicetree-warnings/j773g;
in
pkgs.runCommandCC "firn-devicetree-schema"
  {
    nativeBuildInputs = with pkgs; [
      bison
      dtc
      flex
      gnumake
      python3Packages.dtschema
      which
      yamllint
    ];
  }
  ''
    cp -r ${src} linux
    chmod -R u+w linux
    cd linux
    patchShebangs scripts >/dev/null
    cp ${kernel.configfile} .config
    make -s ARCH=arm64 olddefconfig >/dev/null
    # Linux 7.3 gives ti,irqs-reserved two types in these TI bindings, and
    # dtschema crashes reporting it; neither concerns an Apple devicetree.
    rm Documentation/devicetree/bindings/interrupt-controller/ti,{pruss-intc,irq-crossbar}.yaml
    if ! make -s ARCH=arm64 dt_binding_check DT_SCHEMA_FILES=${bindings} > ../binding-output 2>&1; then
      cat ../binding-output >&2
      exit 1
    fi
    mkdir -p $out
    failed=0
    for board in j713 j773g; do
      cp ../binding-output ../output
      if ! make -s ARCH=arm64 CHECK_DTBS=y apple/t8132-$board.dtb >> ../output 2>&1; then
        cat ../output >&2
        exit 1
      fi
      sed -e "s|$PWD/||g" -e "s|^arch/arm64/boot/dts/apple/t8132-$board.dtb: ||" ../output \
        | grep -E '^(/soc|Documentation|t8132-(j713|j773g)|[a-z].*@[0-9a-f]+ \()' | sort -u > ../warnings
      case "$board" in
        j713) expected=${expectedAir} ;;
        j773g) expected=${expectedMini} ;;
      esac
      if ! diff -u <(sort -u "$expected") ../warnings; then
        echo "dt-schema reports unexpected warnings for $board." >&2
        failed=1
      fi
      cp ../warnings $out/$board
    done
    python3 ${./check-devicetrees.py} arch/arm64/boot/dts/apple
    test "$failed" -eq 0
  ''
