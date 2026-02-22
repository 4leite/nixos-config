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
  '';
  #    EVDEV_ABS_00=:::8
  #   EVDEV_ABS_01=:::8

  services.vscode-server.enable = true;

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

}
