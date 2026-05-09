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
  chuwi-ltsm-hack = pkgs.callPackage ../../packages/chuwi-ltsm-hack.nix {
    kernel = config.boot.kernelPackages.kernel;
  };
  chuwi-tablet-mode-daemon = pkgs.callPackage ../../packages/chuwi-tablet-mode-daemon.nix { };
  chuwi-create-base-accelerometer = pkgs.writeShellScript "chuwi-create-base-accelerometer" ''
    for device in /sys/bus/i2c/devices/i2c-*/name; do
      if ${pkgs.gnugrep}/bin/grep -q Synopsys "$device"; then
        echo mxc4005 0x15 > "$(dirname "$device")/new_device" || true
      fi
    done
  '';
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
  ];
  boot.extraModulePackages = [ chuwi-ltsm-hack ];
  boot.kernelModules = [ "chuwi-ltsm-hack" ];
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
      ACCEL_MOUNT_MATRIX=0, -1, 0; -1, 0, 0; 0, 0, 1

    # Ensure the chassis is recognized as a convertible for tablet mode detection
    dmi:bvn*:bvr*:bd*:svnCHUWI*:pnMiniBookX*:*
      CHASSIS_TYPE=31
  '';
  services.udev.extraRules = ''
    # The Chuwi MiniBook X exposes two MXC6655 accelerometers through one
    # MDA6655 ACPI device.  The display sensor is auto-created by the kernel;
    # create the base sensor and tag both with locations so iio-sensor-proxy
    # and the tablet-mode daemon can tell them apart.
    SUBSYSTEM=="iio", KERNEL=="iio*", SUBSYSTEMS=="i2c", DEVPATH=="*/i2c-*/i2c-MDA6655:00/iio:device*", ENV{ACCEL_LOCATION}="display", ENV{ACCEL_MOUNT_MATRIX}="0,-1,0;1,0,0;0,0,1", RUN+="${chuwi-create-base-accelerometer}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="iio-sensor-proxy.service"
    SUBSYSTEM=="iio", KERNEL=="iio*", SUBSYSTEMS=="i2c", DEVPATH=="*/i2c-*/*-0015/iio:device*", ENV{ACCEL_LOCATION}="base", ENV{ACCEL_MOUNT_MATRIX}="0,-1,0;1,0,0;0,0,1", RUN{builtin}+="kmod load chuwi-ltsm-hack", TAG+="systemd", ENV{SYSTEMD_WANTS}+="chuwi-tablet-mode.service iio-sensor-proxy.service"
  '';
  #    EVDEV_ABS_00=:::8
  #   EVDEV_ABS_01=:::8

  # services.vscode-server.enable = true;

  systemd.services.chuwi-tablet-mode = {
    description = "Chuwi MiniBook X dual-accelerometer tablet-mode detection";
    after = [ "iio-sensor-proxy.service" ];
    wants = [ "iio-sensor-proxy.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${chuwi-tablet-mode-daemon}/bin/chuwi-angle-sensor --interval 0.5 --threshold 45 --hysteresis 20 --tilt-threshold 20 --jerk-threshold 6 ${chuwi-tablet-mode-daemon}/bin/chuwi-tablet-control";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

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
    chuwi-tablet-mode-daemon
    iw
    usbutils
    ethtool
  ];

  services.cloudflare-warp.enable = false;

}
