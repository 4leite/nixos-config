# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  ...
}:
let
  bambam = import ../../packages/bambam.nix { inherit pkgs; };
  # iio-sensor-proxy reports the normal laptop posture as right-up with the
  # raw/identity display accelerometer matrix.  Rotate the display sensor
  # vector so normal laptop posture reports as normal.  Keep the base sensor
  # transform explicit and separate while upstream-first hinge/tablet support is
  # re-evaluated.
  chuwi-display-accel-matrix = "0,-1,0;1,0,0;0,0,1";
  chuwi-base-accel-matrix = "1,0,0;0,1,0;0,0,1";
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
    # Good: fixes the MiniBook X N150 portrait-native DSI panel baseline.
    # Display accelerometer calibration is handled separately below.
    "video=DSI-1:panel_orientation=right_side_up"
  ];
  boot.extraModprobeConfig = ''
    options intel-hid enable_sw_tablet_mode=1
  '';

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

    sensor:modalias:acpi:MDA6655*:dmi:*:svnCHUWI*:pnMiniBookX:*
      ACCEL_MOUNT_MATRIX=${chuwi-display-accel-matrix}

    # Ensure the chassis is recognized as a convertible for tablet mode detection
    dmi:bvn*:bvr*:bd*:svnCHUWI*:pnMiniBookX*:*
      CHASSIS_TYPE=31
  '';
  services.udev.extraRules = ''
    # The Chuwi MiniBook X exposes two MXC6655 accelerometers through one
    # MDA6655 ACPI device.  The display sensor is auto-created by the kernel;
    # create the base sensor and tag both with locations so iio-sensor-proxy
    # can tell them apart during upstream-first baseline testing.
    SUBSYSTEM=="iio", KERNEL=="iio*", SUBSYSTEMS=="i2c", DEVPATH=="*/i2c-*/i2c-MDA6655:00/iio:device*", ENV{ACCEL_LOCATION}="display", ENV{ACCEL_MOUNT_MATRIX}="${chuwi-display-accel-matrix}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="iio-sensor-proxy.service"
    SUBSYSTEM=="iio", KERNEL=="iio*", SUBSYSTEMS=="i2c", DEVPATH=="*/i2c-*/*-0015/iio:device*", ENV{ACCEL_LOCATION}="base", ENV{ACCEL_MOUNT_MATRIX}="${chuwi-base-accel-matrix}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="iio-sensor-proxy.service"
  '';
  #    EVDEV_ABS_00=:::8
  #   EVDEV_ABS_01=:::8

  # services.vscode-server.enable = true;

  hardware.sensor.iio.enable = true;

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
  environment.systemPackages = with pkgs; [
    bambam.bambam
    pkgs.cage
    pkgs.wlr-randr
    pkgs.xwayland-satellite
    iw
    usbutils
    ethtool
  ];

  services.cloudflare-warp.enable = false;

}
