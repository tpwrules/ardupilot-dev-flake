{ stdenv
, lib
, cmake
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "micro-cdr";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-CDR";
    rev = "99672492c5ef9fc378a8835b0bce9b2f7fa41306";
    hash = "sha256-OfxsJGD3nFb+92rYvZ/YF6Qj+3ZwDiSIvZaTq3flcJQ=";
  };

  nativeBuildInputs = [ cmake ];

  postInstall = ''
    cp -r $out/{include,lib} $out/microcdr-*
  '';

}
