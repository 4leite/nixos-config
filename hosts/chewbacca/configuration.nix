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

  networking.hostName = "chewbacca"; # Define your hostname.

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.graphics.enable = true;

  # Use Wayland by default for interactive users, but keep the Bambam
  # session as an X11 session (installed under share/xsessions) so it
  # runs in a dedicated X11 session. This enables Wayland for other
  # users while still allowing Bambam to use X11.
  services.displayManager.gdm.wayland = true;

  # Allow accounts with empty passwords to log in via the GDM greeter
  # (only for the gdm-password PAM service). This must be paired with
  # giving the account an empty password (done in users/bambam.nix).
  security.pam.services."gdm-password".allowNullPassword = true;

  # Ensure AccountsService has a recorded session for the `bambam` user
  # so GDM will default to the Bambam session for that account.
  systemd.services.set-bambam-accounts = {
    description = "Create AccountsService entry for bambam user";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        /bin/sh -c '\
        cat > /var/lib/AccountsService/users/bambam <<'EOF'\
        [User]\
        XSession=bambam\
        SystemAccount=false\
        'EOF'\
      '';
    };
  };

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
  services.xserver.enable = true;

  environment.systemPackages = with pkgs; [ bambam.bambamPkg ];

  # Some DMs (including GDM) expect session files under
  # /usr/share/xsessions or /etc/X11/sessions. The package provides the
  # desktop file under its store path; expose it into /etc so GDM can
  # discover the X11 session even if the session directory from the
  # store isn't linked into the profile.
  environment.etc."usr/share/xsessions/bambam.desktop".source =
    "${bambam.bambamPkg}/share/xsessions/bambam.desktop";

  environment.etc."X11/sessions/bambam.desktop".source =
    "${bambam.bambamPkg}/share/xsessions/bambam.desktop";

  # The Bambam package provides its own desktop/session files under
  # $out/share/xsessions and $out/share/wayland-sessions, so no
  # environment.etc entries are needed here.
  # Some display managers look in /usr/share/xsessions; create the
  # session file there by writing to /etc/../usr/share/xsessions which
  # resolves to /usr/share/xsessions when Nix builds the system.
  environment.etc."../usr/share/xsessions/bambam.desktop".source =
    "${bambam.bambamPkg}/share/xsessions/bambam.desktop";

  # Ensure the xsessions file is visible to display managers by creating
  # a symlink under /usr/share/xsessions via systemd-tmpfiles during boot/activation.
  systemd.tmpfiles.rules = [
    "L+ /usr/share/xsessions/bambam.desktop - - - - ${bambam.bambamPkg}/share/xsessions/bambam.desktop"
  ];
}
