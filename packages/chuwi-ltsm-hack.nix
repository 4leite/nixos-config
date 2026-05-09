{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
}:

stdenv.mkDerivation {
  pname = "chuwi-ltsm-hack";
  version = "unstable-2024-12-30";

  src = fetchFromGitHub {
    owner = "rhalkyard";
    repo = "minibook-dual-accelerometer";
    rev = "2bd40f507dd97707ebaa93b88c6b662bf5e5b801";
    hash = "sha256-WMPgr8SimfVAJ5o1ePNW0Yp4TjDhbmlT9aTiAWSC8+Y=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  preBuild = ''
    cd hack-driver
  '';

  installPhase = ''
    runHook preInstall

    install -Dm444 chuwi-ltsm-hack.ko \
      $out/lib/modules/${kernel.modDirVersion}/misc/chuwi-ltsm-hack.ko

    runHook postInstall
  '';

  meta = {
    description = "Kernel module exposing the Chuwi MiniBook X LTSM tablet-mode ACPI method";
    homepage = "https://github.com/rhalkyard/minibook-dual-accelerometer";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
