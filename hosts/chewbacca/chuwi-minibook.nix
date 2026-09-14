{
  pkgs,
  inputs,
  linuxPackages ? pkgs.linuxPackages,
}:
let
  inherit (pkgs) lib stdenv stdenvNoCC;
  kernel = linuxPackages.kernel;

  mkKernelModule =
    {
      pname,
      src,
      moduleName ? pname,
      version ? "1.0",
    }:
    stdenv.mkDerivation {
      inherit pname version src;

      nativeBuildInputs = kernel.moduleBuildDependencies;
      hardeningDisable = [
        "pic"
        "format"
      ];
      dontConfigure = true;

      buildPhase = ''
        runHook preBuild
        make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -D -m 0644 ${moduleName}.ko $out/lib/modules/${kernel.modDirVersion}/extra/${moduleName}.ko
        runHook postInstall
      '';

      meta = {
        description = "${pname} kernel module for Chuwi MiniBook X";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
      };
    };

  goodixSource = stdenvNoCC.mkDerivation {
    pname = "goodix-ts-source";
    version = "${kernel.version}-minibook1";
    dontUnpack = true;
    nativeBuildInputs = [
      pkgs.gnutar
      pkgs.xz
      pkgs.patch
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out

      tar -xf ${kernel.src} \
        --strip-components=4 \
        -C $out \
        linux-${kernel.version}/drivers/input/touchscreen/goodix.c \
        linux-${kernel.version}/drivers/input/touchscreen/goodix.h \
        linux-${kernel.version}/drivers/input/touchscreen/goodix_fwupload.c

      cp ${inputs.chuwi-minibook}/modules/goodix_ts/Kbuild $out/
      cp ${inputs.chuwi-minibook}/modules/goodix_ts/goodix_resume.patch $out/

      chmod u+w $out/goodix.c
      (cd $out && patch -p1 < goodix_resume.patch)

      runHook postInstall
    '';

    meta = {
      description = "Patched Goodix touchscreen module source for kernel ${kernel.version}";
      license = lib.licenses.gpl2;
      platforms = lib.platforms.linux;
    };
  };

  goodixTs = stdenv.mkDerivation {
    pname = "goodix_ts";
    version = "${kernel.version}-minibook1";
    src = goodixSource;

    nativeBuildInputs = kernel.moduleBuildDependencies;
    hardeningDisable = [
      "pic"
      "format"
    ];
    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -D -m 0644 goodix_ts.ko $out/lib/modules/${kernel.modDirVersion}/extra/goodix_ts.ko
      runHook postInstall
    '';

    meta = {
      description = "Patched Goodix touchscreen kernel module for Chuwi MiniBook X";
      license = lib.licenses.gpl2;
      platforms = lib.platforms.linux;
    };
  };

  goodixFirmware = stdenvNoCC.mkDerivation {
    pname = "goodix-9110-firmware";
    version = "minibook1";
    src = "${inputs.chuwi-minibook}/modules/goodix_ts";
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -D -m 0644 goodix_cfg.bin $out/lib/firmware/goodix_9110_cfg.bin
      runHook postInstall
    '';

    meta = {
      description = "Goodix touchscreen firmware blob for Chuwi MiniBook X";
      license = lib.licenses.unfreeRedistributableFirmware;
      platforms = lib.platforms.linux;
    };
  };

  vbtPatch = stdenv.mkDerivation {
    pname = "chuwi-vbt-patch";
    version = "1.0";
    src = "${inputs.chuwi-minibook}/vbt_patch";
    dontConfigure = true;
    nativeBuildInputs = [
      pkgs.clang
      pkgs.gnutar
      pkgs.xz
    ];

    buildPhase = ''
      runHook preBuild
      tar -xf ${kernel.src} \
        --strip-components=6 \
        linux-${kernel.version}/drivers/gpu/drm/i915/display/intel_vbt_defs.h \
        linux-${kernel.version}/drivers/gpu/drm/i915/display/intel_dsi_vbt_defs.h
      clang -Wall -Wextra -O2 -o vbt_patch vbt_patch.c
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -D -m 0755 vbt_patch $out/bin/vbt_patch
      runHook postInstall
    '';

    meta = {
      description = "MiniBook VBT patch utility";
      license = lib.licenses.gpl2Plus;
      platforms = lib.platforms.linux;
    };
  };

  minibookTools = stdenvNoCC.mkDerivation {
    pname = "chuwi-minibook-tools";
    version = "1.0";
    src = "${inputs.chuwi-minibook}/tools";
    dontBuild = true;
    nativeBuildInputs = [ pkgs.gnused ];

    installPhase = ''
      runHook preInstall
      install -D -m 0755 check-status.sh $out/bin/chuwi-check-status
      install -D -m 0755 dptf-status.sh $out/bin/chuwi-dptf-status
      install -D -m 0755 gpu-status.sh $out/bin/chuwi-gpu-status
      install -D -m 0755 detect-hardware.sh $out/bin/chuwi-detect-hardware
      install -D -m 0755 update-vbt-clock.sh $out/bin/chuwi-update-vbt-clock

      substituteInPlace $out/bin/chuwi-update-vbt-clock \
        --replace 'readonly VBT_TOOL="''${SCRIPT_DIR}/../vbt_patch/vbt_patch"' 'readonly VBT_TOOL="${vbtPatch}/bin/vbt_patch"'

      runHook postInstall
    '';

    meta = {
      description = "Diagnostic and maintenance tools for Chuwi MiniBook X";
      license = lib.licenses.bsd0;
      platforms = lib.platforms.linux;
    };
  };
in
{
  dptfEnabler = mkKernelModule {
    pname = "dptf_enabler";
    src = "${inputs.chuwi-minibook}/modules/dptf_enabler";
  };

  i2cDesignwareSpklen = mkKernelModule {
    pname = "i2c_designware_spklen";
    src = "${inputs.chuwi-minibook}/modules/i2c_designware_spklen";
  };

  minibookEc = mkKernelModule {
    pname = "minibook_ec";
    src = "${inputs.chuwi-minibook}/modules/minibook_ec";
  };

  inherit
    goodixTs
    goodixFirmware
    minibookTools
    vbtPatch
    ;

  iioSensorProxy = pkgs.iio-sensor-proxy.overrideAttrs (oldAttrs: {
    version = "3.9.minibook1";
    src = "${inputs.chuwi-minibook}/iio-sensor-proxy";
    patches = (oldAttrs.patches or [ ]) ++ [ ./chuwi-minibook-sensor.patch ];
    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.libdrm ];
  });

  thermald = pkgs.thermald.overrideAttrs (_: {
    version = "2.5.11.minibook1";
    src = "${inputs.chuwi-minibook}/thermal_daemon";
  });
}