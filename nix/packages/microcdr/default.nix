{ stdenv
, lib
, cmake
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "micro-cdr";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-CDR";
    rev = "3d1b17703c7cf4f22def2910bc845bdb5152d7b5";
    hash = "sha256-X5kE8dMpwXL2hzpT6vY+BHa70Fw21z++vs8nVARpxNk=";
  };

  nativeBuildInputs = [ cmake ];

  postInstall = ''
    cp -r $out/{include,lib} $out/microcdr-*
  '';

}
