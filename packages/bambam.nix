{ pkgs, ... }:

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

  bambamPkg =
    pkgs.runCommand "bambam"
      {
        buildInputs = [ pythonWithDeps ];
      }
      ''
          mkdir -p $out/share/bambam
          cp -r ${src}/* $out/share/bambam/
          mkdir -p $out/bin
          install -Dm755 /dev/stdin $out/bin/bambam <<EOF
        #!/bin/sh
        exec ${pythonWithDeps}/bin/python $out/share/bambam/bambam.py
        EOF
          mkdir -p $out/share/applications
          cat > $out/share/applications/bambam.desktop <<EOF
        [Desktop Entry]
        Name=BamBam
        Comment=Keyboard mashing and doodling game for babies and toddlers.
        Exec=$out/bin/bambam --in-dedicated-session
        TryExec=$out/bin/bambam
        Icon=bambam
        Type=Application
        EOF
      '';

in

{
  bambamPkg = bambamPkg;

}
