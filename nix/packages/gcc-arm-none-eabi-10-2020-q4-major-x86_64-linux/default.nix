{ stdenv
, lib
, fetchzip
, autoPatchelfHook
, ncurses5
}:

stdenv.mkDerivation {
  pname = "gcc-arm-none-eabi";
  version = "10-2020-q4-major";

  src = fetchzip {
    url = "https://firmware.ardupilot.org/Tools/STM32-tools/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2";
    hash = "sha256-guqfEz4XtzI51FGbyAh3RFH6mlUCMO3JgnmyruBvA5I=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib
    ncurses5
  ];

  dontStrip = true; # avoid doing weird stuff to binaries
  dontPatchELF = true;

  postPatch = ''
    # we are not deigning to supply python2 to the GDB plugin
    rm bin/arm-none-eabi-gdb-py
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -r * $out

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/arm-none-eabi-gcc --version

    runHook postInstallCheck
  '';

  meta = {
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
