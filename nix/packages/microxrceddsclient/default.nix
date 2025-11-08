{ stdenv
, lib
, cmake
, fetchFromGitHub
, microcdr
}:

stdenv.mkDerivation {
  pname = "micro-xrce-dds-client";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Client";
    rev = "bdfa28090efc8c0e89aa5c95cdf0878c8289a18b";
    hash = "sha256-WTtPbLL2ERNN6n/aT2mhNgG7VjGYXyPeO6ddhYfJTVE=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ microcdr ];

}
