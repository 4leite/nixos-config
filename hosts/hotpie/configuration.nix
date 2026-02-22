# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  #  vscode-insiders-bin = pkgs.stdenv.mkDerivation {
  #    pname = "vscode-insiders-bin";
  #    version = "latest";
  #    src = pkgs.fetchurl {
  #      name = "vscode-insiders-latest-linux-x64.tar.gz";
  #      url = "https://update.code.visualstudio.com/latest/linux-x64/insider";
  #      hash = "sha256-YBK3RXNUjSf+JaS+VVSh09QYIa/WxTprz50+wQvmSz0=";
  #    };
  #    dontStrip = true;
  #    installPhase = ''
  #      mkdir -p $out/bin $out/lib/vscode-insiders
  #      cp -r . $out/lib/vscode-insiders/
  #      ln -s $out/lib/vscode-insiders/bin/code-insiders $out/bin/code-insiders
  #    '';
  #  };
  #
  #  vscode-insiders-fhs = unstable.buildFHSEnv {
  #    name = "code-insiders";
  #    targetPkgs =
  #      p: with p; [
  #        vscode-insiders-bin
  #        # ld-linux and glibc
  #        glibc
  #        # dotnet
  #        curl
  #        icu
  #        libunwind
  #        libuuid
  #        lttng-ust
  #        openssl
  #        zlib
  #        # kerberos / mono
  #        krb5
  #        # electron / chromium
  #        alsa-lib
  #        at-spi2-atk
  #        at-spi2-core
  #        atk
  #        cairo
  #        cups
  #        dbus
  #        expat
  #        fontconfig
  #        freetype
  #        gdk-pixbuf
  #        glib
  #        gtk3
  #        libdrm
  #        libGL
  #        libnotify
  #        libxkbcommon
  #        nspr
  #        nss
  #        pango
  #        libsecret
  #        libX11
  #        libXScrnSaver
  #        libXcomposite
  #        libXcursor
  #        libXdamage
  #        libXext
  #        libXfixes
  #        libXi
  #        libXrandr
  #        libXrender
  #        libXtst
  #        libxcb
  #        libxshmfence
  #        # extra libs needed at runtime
  #        stdenv.cc.cc # libstdc++.so.6
  #        libxkbfile
  #        libXtst
  #      ];
  #    multiPkgs =
  #      p: with p; [
  #        # these need to be in both 32-bit and 64-bit paths
  #        mesa # libgbm.so.1, libGL, etc
  #        libgbm # explicit libgbm.so.1
  #        udev # libudev.so.1
  #      ];
  #    runScript = "code-insiders";
  #  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "hotpie"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  users.users.jon.extraGroups = [ "uinput" ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # new
  # services.displayManager.gdm.wayland = false;
  # old
  services.xserver.displayManager.gdm.wayland = true;

  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    lutris
    mono
    wine
    gearlever
    autokey
    # vscode-insiders-fhs
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Ensure the uinput group exists
  users.groups.uinput = { };

  # Enable the uinput module
  boot.kernelModules = [ "uinput" ];

  # Enable uinput
  hardware.uinput.enable = true;

  # Set up udev rules for uinput
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  # Add the Kanata service user to necessary groups
  systemd.services.kanata-internalKeyboard.serviceConfig = {
    SupplementaryGroups = [
      "input"
      "uinput"
    ];
  };

  services.kanata = {
    enable = true;
    keyboards = {
      internalKeyboard = {
        devices = [
          # Replace the paths below with the appropriate device paths for your setup.
          # Use `ls /dev/input/by-path/` to find your keyboard devices.
          "/dev/input/by-path/pci-0000:00:14.0-usb-0:4:1.1-event-kbd"
          "/dev/input/by-path/pci-0000:00:14.0-usb-0:5:1.0-event-kbd"
          "/dev/input/by-path/pci-0000:00:14.0-usb-0:5:1.1-event-kbd"
          "/dev/input/by-path/pci-0000:00:14.0-usbv2-0:4:1.1-event-kbd"
          "/dev/input/by-path/pci-0000:00:14.0-usbv2-0:5:1.0-event-kbd"
          "/dev/input/by-path/pci-0000:00:14.0-usbv2-0:5:1.1-event-kbd"
        ];
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
                    (defsrc
                     Numpad0 Numpad7
                    )
                    (defalias
                     hideout (macro Enter Slash KeyH KeyI KeyD KeyE KeyO KeyU KeyT Enter)
          	   logout (macro Enter Slash KeyE KeyX KeyI KeyT Enter)
                    )
          	  (deflayer poe
          	   @hideout @logout
          	  )
        '';
      };
    };
  };

}
