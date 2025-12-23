{ pkgs, ... }:

# Provide a local package for Bambam. Nixpkgs may not ship this package
# under the name `bambam`, so we build it from upstream here.
#
# IMPORTANT: you must replace the sha256 in `packages/bambam.nix` if you
# change the `rev`. You can obtain the correct hash with:
#
#  nix-prefetch-git https://github.com/porridge/bambam --rev v1.4.1
#
# and copy the resulting "sha256" value into `packages/bambam.nix`.
let
  src = pkgs.fetchFromGitHub {
    owner = "porridge";
    repo = "bambam";
    rev = "v1.4.1";
    sha256 = "1xr2mlz9cjd3i1l9qnrikj2gmmbyd96ryqchn36dvghn1dj265r4";
  };

  pythonWithDeps = pkgs.python3.withPackages (
    p: with p; [
      pygame
      pyyaml
    ]
  );

  bambam =
    pkgs.runCommand "bambam"
      {
        buildInputs = [
          pythonWithDeps
          pkgs.cage
          pkgs.wlr-randr
          pkgs.xwayland-satellite

        ];
        propagatedBuildInputs = [
          pythonWithDeps
          pkgs.cage
          pkgs.wlr-randr
          pkgs.xwayland-satellite
        ];
        passthru = {
          providedSessions = [ "bambam" ];
        };
      }
      ''
        # Build bambam package with session support
        mkdir -p $out/share/bambam
        cp -r ${src}/* $out/share/bambam/
        patchShebangs $out/share/bambam/bambam.py
        mkdir -p $out/bin
        ln -s $out/share/bambam/bambam.py $out/bin/bambam
        cat > $out/bin/bambam-satellite <<EOF
        #!/bin/sh
        wlr-randr --output DSI-1 --transform 270
        XDISP=":12"
        xwayland-satellite "\$XDISP" &
        sat_pid=\$!
        sleep 0.2
        exec env -u WAYLAND_DISPLAY -u XDG_SESSION_TYPE \
        DISPLAY="\$XDISP" SDL_VIDEODRIVER=x11 \
        $out/share/bambam/bambam.py -m -d -D
        kill "\$sat_pid" || true
        EOF
        chmod +x $out/bin/bambam-satellite
        cat > $out/bin/bambam-cage <<EOF
        #!/bin/sh
        exec ${pkgs.cage}/bin/cage $out/bin/bambam-satellite
        EOF
        chmod +x $out/bin/bambam-cage
        mkdir -p $out/share/applications
        cat > $out/share/applications/bambam.desktop <<EOF
        [Desktop Entry]
        Name=BamBam
        Comment=Keyboard mashing and doodling game for babies and toddlers.
        Exec=$out/bin/bambam-cage
        TryExec=$out/bin/bambam-cage
        Icon=bambam
        Type=Application
        EOF
        mkdir -p $out/share/wayland-sessions
        cat > $out/share/wayland-sessions/bambam.desktop <<EOF
        [Desktop Entry]
        Name=BamBam
        Comment=Start BamBam in a dedicated session
        Exec=$out/bin/bambam-cage
        TryExec=$out/bin/bambam-cage
        Type=Application
        EOF
      '';
in
{
  bambam = bambam;

}
