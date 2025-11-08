{ stdenv
, lib
, cmake
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "foonathan_memory";
  version = "v0.7-3";

  src = fetchFromGitHub {
    owner = "foonathan";
    repo = "memory";
    rev = "v0.7-3";
    hash = "sha256-nLBnxPbPKiLCFF2TJgD/eJKJJfzktVBW3SRW2m3WK/s=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    "-DFOONATHAN_MEMORY_BUILD_TESTS=OFF"
  ];
}
