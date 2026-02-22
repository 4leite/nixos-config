# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  nixpkgs-unstable,
  system,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  vscode-insiders-bin = pkgs.stdenv.mkDerivation {
    pname = "vscode-insiders-bin";
    version = "latest";
    src = pkgs.fetchurl {
      name = "vscode-insiders-latest-linux-x64.tar.gz";
      url = "https://update.code.visualstudio.com/latest/linux-x64/insider";
      hash = "sha256-YBK3RXNUjSf+JaS+VVSh09QYIa/WxTprz50+wQvmSz0=";
    };
    dontStrip = true;
    installPhase = ''
      mkdir -p $out/bin $out/lib/vscode-insiders
      cp -r . $out/lib/vscode-insiders/
      ln -s $out/lib/vscode-insiders/bin/code-insiders $out/bin/code-insiders
    '';
  };

  vscode-insiders-fhs = unstable.buildFHSEnv {
    name = "code-insiders";
    targetPkgs =
      p: with p; [
        vscode-insiders-bin
        # ld-linux and glibc
        glibc
        # dotnet
        curl
        icu
        libunwind
        libuuid
        lttng-ust
        openssl
        zlib
        # kerberos / mono
        krb5
        # electron / chromium
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        libdrm
        libGL
        libnotify
        libxkbcommon
        nspr
        nss
        pango
        libsecret
        libX11
        libXScrnSaver
        libXcomposite
        libXcursor
        libXdamage
        libXext
        libXfixes
        libXi
        libXrandr
        libXrender
        libXtst
        libxcb
        libxshmfence
        # extra libs needed at runtime
        stdenv.cc.cc # libstdc++.so.6
        libxkbfile
        libXtst
      ];
    multiPkgs =
      p: with p; [
        # these need to be in both 32-bit and 64-bit paths
        mesa # libgbm.so.1, libGL, etc
        libgbm # explicit libgbm.so.1
        udev # libudev.so.1
      ];
    runScript = "code-insiders";
  };
in
{
  # Set your time zone.
  time.timeZone = "Pacific/Auckland";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_NZ.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_NZ.UTF-8";
    LC_IDENTIFICATION = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
    LC_MONETARY = "en_NZ.UTF-8";
    LC_NAME = "en_NZ.UTF-8";
    LC_NUMERIC = "en_NZ.UTF-8";
    LC_PAPER = "en_NZ.UTF-8";
    LC_TELEPHONE = "en_NZ.UTF-8";
    LC_TIME = "en_NZ.UTF-8";
  };

  # Enable the GNOME Desktop Environment.
  # new
  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;

  # old
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Enable auto-upgrades.
  system.autoUpgrade = {
    enable = true;
    # Run daily
    dates = "daily";
    # Build the new config and make it the default, but don't switch yet.  This will be picked up on reboot.  This helps
    # prevent issues with OpenSnitch configs not well matching the state of the system.
    operation = "boot";
  };

  # Limit nix rebuilds priority.  When left on the default is uses all available reouses which can make the system unusable
  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  # Install firefox.
  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    chromium
    ghostty
    git
    xclip
    gparted
    pciutils
    nodejs
    nodePackages.pnpm
    discord
    xdg-utils
    google-chrome
    openssl
    gimp
    qbittorrent
    tor
    tor-browser
    android-tools
    vlc
    nixfmt-rfc-style
    signal-desktop
    nmap
    bind
    sqlitebrowser
    traceroute
    gh
    unstable.vscode.fhs
    #    (unstable.vscode.override { isInsiders = true; }).fhs
    vscode-insiders-fhs
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
  };

  environment.shellAliases = {
    nxs = "sudo nixos-rebuild switch --flake ~/.dot";
    nxu = "nix flake update --flake ~/.dot && sudo nixos-rebuild switch --flake ~/.dot";
    p = "pnpm";
  };

  # Ensure xdg mime handling is enabled
  xdg.mime.enable = true;

  # Set Discord as the default application for its protocol
  xdg.mime.defaultApplications = {
    "x-scheme-handler/discord" = [ "discord.desktop" ];
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
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # manage disk space
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    persistent = true;
    dates = "05:00:00";
    options = "--delete-older-than 7d";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
