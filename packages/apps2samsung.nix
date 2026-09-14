{ pkgs }:

let
  pname = "apps2samsung";
  version = "2.7.9";

  src = pkgs.fetchurl {
    url = "https://github.com/Apps2Samsung/Apps2Samsung/releases/download/v${version}/Apps2Samsung-v${version}-linux-x64.AppImage";
    hash = "sha256-oozE67ixeXbc6R+KVZFb4dBEBFraFCudRF6Mw9PkOLo=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = p: [
    p.icu
    p.openssl
    p.krb5
    p.zlib
  ];

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/apps2samsung.png \
      $out/share/icons/hicolor/256x256/apps/apps2samsung.png
    install -m 444 -D ${appimageContents}/apps2samsung.desktop \
      $out/share/applications/apps2samsung.desktop
    substituteInPlace $out/share/applications/apps2samsung.desktop \
      --replace-fail 'Exec=Apps2Samsung' 'Exec=apps2samsung'
  '';

  meta = {
    description = "Install applications on Samsung Tizen devices";
    homepage = "https://github.com/Apps2Samsung/Apps2Samsung";
    license = pkgs.lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
