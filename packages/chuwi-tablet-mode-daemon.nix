{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  python3,
  python3Packages,
}:

stdenv.mkDerivation {
  pname = "chuwi-tablet-mode-daemon";
  version = "unstable-2024-12-30";

  src = fetchFromGitHub {
    owner = "rhalkyard";
    repo = "minibook-dual-accelerometer";
    rev = "2bd40f507dd97707ebaa93b88c6b662bf5e5b801";
    hash = "sha256-WMPgr8SimfVAJ5o1ePNW0Yp4TjDhbmlT9aTiAWSC8+Y=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 angle-sensor-service/angle-sensor.py $out/bin/chuwi-angle-sensor
    install -Dm755 angle-sensor-service/chuwi-tablet-control.sh $out/bin/chuwi-tablet-control

    wrapProgram $out/bin/chuwi-angle-sensor \
      --prefix PATH : ${lib.makeBinPath [ python3 ]} \
      --prefix PYTHONPATH : ${
        python3Packages.makePythonPath [
          python3Packages.numpy
          python3Packages.pyudev
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Userspace dual-accelerometer tablet-mode daemon for the Chuwi MiniBook X";
    homepage = "https://github.com/rhalkyard/minibook-dual-accelerometer";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
