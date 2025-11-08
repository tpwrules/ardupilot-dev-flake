{ stdenv
, lib
, cmake
, fetchFromGitHub
, microxrceddsclient
, fastcdr
, foonathan_memory
, fastdds
, tinyxml-2
, spdlog
}:

stdenv.mkDerivation {
  pname = "micro-xrce-dds-agent";
  version = "2.4.2";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Agent";
    rev = "57d086216d01ec43121845d385894a25987f8a2c";
    hash = "sha256-w8lq54VO5PgqIwvaxal37zKoI7YhcAwAmT66ZutHtGE=";
  };

  nativeBuildInputs = [ cmake ];


  cmakeFlags = [
    "-DUAGENT_USE_SYSTEM_FASTCDR=ON"
  ]; 

  propagatedBuildInputs = [ microxrceddsclient fastcdr foonathan_memory fastdds tinyxml-2 spdlog ];

  patchPhase = ''
    substituteInPlace cmake/SuperBuild.cmake \
      --replace-fail 'fastrtps ''${_fastdds_version} EXACT' 'fastrtps ''${_fastdds_version}'
  '';
}
