{ stdenv
, lib
, cmake
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "spdlog";
  version = "1.9.2";

  src = fetchFromGitHub {
    owner = "gabime";
    repo = "spdlog";
    rev = "v1.9.2";
    hash = "sha256-GSUdHtvV/97RyDKy8i+ticnSlQCubGGWHg4Oo+YAr8Y=";
  };

  nativeBuildInputs = [ cmake ];

  postPatch = ''
    substituteInPlace cmake/spdlog.pc.in \
      --replace "''${exec_prefix}/@CMAKE_INSTALL_LIBDIR@" "@CMAKE_INSTALL_FULL_LIBDIR@"
  '';
}
