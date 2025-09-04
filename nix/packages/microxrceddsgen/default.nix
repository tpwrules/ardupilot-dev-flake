{ lib
, fetchFromGitHub
, buildGradlePackage
, gradle_7-unwrapped
, openjdk11_headless
, makeWrapper
}:

buildGradlePackage {
  pname = "microxrceddsgen";
  version = "4.7.1-ardupilot";
  
  # generated using nix run github:tadfisher/gradle2nix/f8c0afcd2936bce1eda300b74250ec1810c41c2e -- -t assemble
  # (this git hash is head of v2 at the time of writing)
  # in a clean checkout of the source with postPatch applied
  lockFile = ./gradle.lock;

  gradleInstallFlags = [ "assemble" ];

  gradle = gradle_7-unwrapped;
  buildJdk = openjdk11_headless;
  
  src = fetchFromGitHub {
    owner = "ArduPilot";
    repo = "Micro-XRCE-DDS-Gen";
    rev = "v4.7.1";
    hash = "sha256-6mDIa6o6lrXHxYX+7HNPvUV8XFVuMeS1rYc3KSt+hLU=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    # remove git submodule call
    substituteInPlace build.gradle \
      --replace-fail 'buildIDLParser.dependsOn submodulesUpdate' ""
  '';

  postInstall = ''
    # install JAR
    mkdir -p $out
    cp -r share $out/

    # make binary to run it
    makeWrapper ${lib.getExe openjdk11_headless} $out/bin/microxrceddsgen --add-flags "-jar $out/share/microxrceddsgen/java/microxrceddsgen.jar"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    # make sure the binary does something
    $out/bin/microxrceddsgen -version

    runHook postInstallCheck
  '';
}
