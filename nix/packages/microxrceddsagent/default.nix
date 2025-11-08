{ stdenv
, lib
, cmake
, fetchFromGitHub
, microxrceddsclient
, fastcdr
}:

stdenv.mkDerivation {
  pname = "micro-xrce-dds-agent";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Agent";
    rev = "155cfaaf8b7abac2e85d4a62d3649b09ace0be55";
    hash = "sha256-nBJ+WuoZhB3+/NiYAH/l1r0BK1aFzAUfGpyOKpWC1sg=";
  };

  nativeBuildInputs = [ cmake ];


  cmakeFlags = [
    "-DUAGENT_USE_SYSTEM_FASTCDR=ON"
  ]; 

  buildInputs = [ microxrceddsclient fastcdr ];
}
