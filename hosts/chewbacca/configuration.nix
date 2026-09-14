# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  apps2samsung = import ../../packages/apps2samsung.nix { inherit pkgs; };
  bambam = import ../../packages/bambam.nix { inherit pkgs; };
  chuwiMinibook = import ./chuwi-minibook.nix {
    inherit pkgs inputs;
    linuxPackages = pkgs.linuxPackages;
  };
  gnomeTabletExitOrientation = pkgs.writeShellApplication {
    name = "gnome-tablet-exit-orientation";
    runtimeInputs = [
      (pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pygobject3 ]))
    ];
    text = ''
      exec python3 ${./gnome-tablet-exit-orientation.py} "$@"
    '';
  };

  # Full upstream stack toggle for this host.
  enable-chuwi-minibook-stack = true;

  # Optional stack components.
  enable-chuwi-goodix-ts = true;
  enable-chuwi-vbt-tools = true;

  # Keep the portrait-native panel's known-good baseline. SensorProxy reports
  # measured chassis orientation; Mutter combines it with this DRM orientation.
  use-fixed-panel-orientation = true;

  # Recommended by upstream check-status to mitigate DSI glitches.
  disable-panel-self-refresh = true;

  # Keep upstream dptf_enabler defaults: extra fan/sensor participants disabled.
  dptf-enable-fans = false;
  dptf-enable-sensors = false;
in

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "iwlwifi.power_save=0"
    "iwlwifi.uapsd_disable=1"
  ]
  ++ lib.optionals disable-panel-self-refresh [ "i915.enable_psr=0" ]
  ++ lib.optionals use-fixed-panel-orientation [ "video=DSI-1:panel_orientation=right_side_up" ];

  boot.extraModprobeConfig = ''
    options intel-hid enable_sw_tablet_mode=1
    options dptf_enabler enable_fans=${if dptf-enable-fans then "1" else "0"} enable_sensors=${
      if dptf-enable-sensors then "1" else "0"
    }
  '';

  boot.extraModulePackages = lib.optionals enable-chuwi-minibook-stack (
    [
      chuwiMinibook.dptfEnabler
      chuwiMinibook.minibookEc
      chuwiMinibook.i2cDesignwareSpklen
      pkgs.linuxPackages.acpi_call
    ]
    ++ lib.optionals enable-chuwi-goodix-ts [ chuwiMinibook.goodixTs ]
  );

  boot.kernelModules = lib.optionals enable-chuwi-minibook-stack (
    [
      "dptf_enabler"
      "minibook_ec"
      "i2c_designware_spklen"
      # The patched sensor proxy reads both MXC6655 accelerometers directly,
      # emits SW_TABLET_MODE through uinput, and invokes the firmware LTSM
      # method through acpi_call to disable the keyboard/touchpad when folded.
      "i2c-dev"
      "uinput"
      "acpi_call"
    ]
    ++ lib.optionals enable-chuwi-goodix-ts [ "goodix_ts" ]
  );

  networking.hostName = "chewbacca"; # Define your hostname.

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;

  hardware.graphics.enable = true;

  services.xserver.enable = true;

  services.desktopManager.gnome.enable = true;

  services.displayManager.sessionPackages = [ bambam.bambam ];

  # Allow accounts with empty passwords to log in via the GDM greeter
  # (only for the gdm-password PAM service). This must be paired with
  # giving the account an empty password (done in users/bambam.nix).
  security.pam.services."gdm-password".allowNullPassword = true;

  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.mutter]
    experimental-features=['scale-monitor-framebuffer', 'xwayland-native-scaling']
  '';

  # fix touchpad jitter
  services.udev.extraHwdb = ''
    evdev:name:XXXX0000:05 0911:5288 Touchpad:dmi:*:pnMiniBookX:*
      EVDEV_ABS_00=:::12:8
      EVDEV_ABS_01=:::12:8
      EVDEV_ABS_35=:::12:8
      EVDEV_ABS_36=:::12:8

    # Ensure the chassis is recognized as a convertible for tablet mode detection
    dmi:bvn*:bvr*:bd*:svnCHUWI*:pnMiniBookX*:*
      CHASSIS_TYPE=31
  '';
  #    EVDEV_ABS_00=:::8
  #   EVDEV_ABS_01=:::8

  # services.vscode-server.enable = true;

  hardware.sensor.iio = {
    enable = true;
    package =
      if enable-chuwi-minibook-stack then chuwiMinibook.iioSensorProxy else pkgs.iio-sensor-proxy;
  };

  # Mutter 50.4 resets a portrait-native panel to a sideways logical transform
  # when SW_TABLET_MODE clears. Preserve the current measured SensorProxy
  # orientation after that transition without replacing the generic interfaces.
  systemd.user.services.gnome-tablet-exit-orientation = {
    description = "Restore measured orientation after leaving GNOME tablet mode";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${gnomeTabletExitOrientation}/bin/gnome-tablet-exit-orientation";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  services.thermald = lib.mkIf enable-chuwi-minibook-stack {
    enable = true;
    package = chuwiMinibook.thermald;
    ignoreCpuidCheck = true;
  };

  hardware.firmware = lib.optionals (enable-chuwi-minibook-stack && enable-chuwi-goodix-ts) [
    chuwiMinibook.goodixFirmware
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # Provide a local package for Bambam. Nixpkgs may not ship this package
  # under the name `bambam`, so we build it from upstream here.
  #
  # IMPORTANT: you must replace the sha256 in `packages/bambam.nix` if you
  # change the `rev`. You can obtain the correct hash with:
  #
  #   nix-prefetch-git https://github.com/porridge/bambam --rev v1.4.1
  #
  # and copy the resulting "sha256" value into `packages/bambam.nix`.
  # Add bambam and cage to the system profile so commands are available.
  environment.systemPackages =
    (with pkgs; [
      apps2samsung
      bambam.bambam
      pkgs.cage
      pkgs.wlr-randr
      pkgs.xwayland-satellite
      iw
      usbutils
      ethtool
    ])
    ++ lib.optionals enable-chuwi-minibook-stack [ chuwiMinibook.minibookTools ]
    ++ lib.optionals (enable-chuwi-minibook-stack && enable-chuwi-vbt-tools) [ chuwiMinibook.vbtPatch ];

  services.cloudflare-warp.enable = false;

}
