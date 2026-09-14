{
  nixpkgs-unstable,
  noctalia,
  pkgs,
  ...
}:
{
  # Keep GNOME available in GDM while adding Niri as a separate session.
  programs.niri = {
    enable = true;
    package = nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.niri;
  };

  # Steam, Discord, and other X11-only applications need XWayland under Niri.
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Services used by Noctalia's network, Bluetooth, battery, and power widgets.
  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Use GTK for file pickers while retaining GNOME's portal for screencasting.
  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.niri."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
  };

  # Work around NVIDIA retaining close to 1 GiB of freed compositor buffers.
  # Upstream: https://github.com/NVIDIA/egl-wayland/issues/126
  # TODO: Remove once https://github.com/NixOS/nixpkgs/pull/468569 (or an
  # equivalent driver-provided Niri profile) is included in our pinned release.
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text =
    builtins.toJSON {
      rules = [
        {
          pattern = {
            feature = "procname";
            matches = "niri";
          };
          profile = "Limit Free Buffer Pool On Wayland Compositors";
        }
      ];
      profiles = [
        {
          name = "Limit Free Buffer Pool On Wayland Compositors";
          settings = [
            {
              key = "GLVidHeapReuseRatio";
              value = 0;
            }
          ];
        }
      ];
    };

  home-manager.users.jon =
    { config, lib, ... }:
    {
      imports = [ noctalia.homeModules.default ];

      # VS Code does not auto-detect a Secret Service backend under Niri. It
      # also renders intermittent black frames with GPU acceleration while its
      # chat editing UI is active on NVIDIA/Wayland. Merge both workarounds into
      # its mutable argv file without replacing IDs maintained by VS Code itself.
      # TODO: Remove when https://github.com/microsoft/vscode/issues/187338 is fixed.
      home.activation.configureVSCodeKeyring = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        argv_file="$HOME/.vscode/argv.json"
        mkdir -p "$(dirname "$argv_file")"

        ${pkgs.python3}/bin/python - "$argv_file" <<'PY'
        import json
        import os
        import re
        import sys
        import tempfile

        path = sys.argv[1]
        data = {}

        if os.path.exists(path):
          with open(path, encoding="utf-8") as handle:
            raw = handle.read()
          without_comments = re.sub(r"(?m)^\s*//.*$", "", raw)
          data = json.loads(without_comments)

        expected = {
          "password-store": "gnome-libsecret",
          "disable-hardware-acceleration": True,
        }

        if any(data.get(key) != value for key, value in expected.items()):
          data.update(expected)
          fd, temporary = tempfile.mkstemp(dir=os.path.dirname(path), text=True)
          try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
              json.dump(data, handle, indent=2)
              handle.write("\n")
            os.chmod(temporary, 0o600)
            os.replace(temporary, path)
          finally:
            if os.path.exists(temporary):
              os.unlink(temporary)
        PY
      '';

      programs.noctalia = {
        enable = true;

        # Runtime overrides made in Noctalia's settings UI remain mutable.
        settings.theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };
      };

      home.file.".local/share/applications/google-chrome-incognito.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Google Chrome Incognito
        GenericName=Private Web Browser
        Comment=Open a new incognito Chrome window
        Exec=${pkgs.google-chrome}/bin/google-chrome-stable --incognito --new-window
        Icon=google-chrome-incognito
        Terminal=false
        Categories=Network;WebBrowser;
        StartupNotify=true
      '';

      home.file.".local/share/icons/hicolor/scalable/apps/google-chrome-incognito.svg".text = ''
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
          <circle cx="32" cy="32" r="30" fill="#4c3c78"/>
          <path fill="#fff" d="M18 25h28l-4-9H22l-4 9Zm1 4h26l4 15H15l4-15Zm7 4a6 6 0 1 0 0 12 6 6 0 0 0 0-12Zm12 0a6 6 0 1 0 0 12 6 6 0 0 0 0-12Zm-6 5a7 7 0 0 1 3 0v3a4 4 0 0 0-3 0v-3Z"/>
        </svg>
      '';

      # Keep Niri's config writable so NiriMod can save directly into this
      # repository and Niri can hot-reload each validated change.
      xdg.configFile."niri/config.kdl".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dot/hosts/hotpie/niri.kdl";
    };
}
