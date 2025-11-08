{ stdenv
, lib
, cmake
, fetchFromGitHub
, microcdr
}:

stdenv.mkDerivation {
  pname = "micro-xrce-dds-client";
  version = "2.4.2";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Client";
    rev = "v2.4.2";
    hash = "sha256-OkKznYOSQrpcTGCVgAV09OxHYP8DlaZhpZX3gjlnKzQ=";
  };

  nativeBuildInputs = [ cmake ];

  propagatedBuildInputs = [ microcdr ];

}
