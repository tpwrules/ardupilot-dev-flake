{ stdenv
, lib
, cmake
, fetchFromGitHub
, microcdr
}:

stdenv.mkDerivation {
  pname = "micro-xrce-dds-client";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Client";
    rev = "9e05a62f3352ce5bf1cec0d2b518391179213ce6";
    hash = "sha256-bh9Om36idZ1ybUNn6vHsm6TUDjIccZHTNKgeT8wr+DU=";
  };

  nativeBuildInputs = [ cmake ];

  propagatedBuildInputs = [ microcdr ];

}
