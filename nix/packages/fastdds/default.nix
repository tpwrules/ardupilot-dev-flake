{ stdenv
, lib
, cmake
, fetchFromGitHub
, fastcdr
, asio
, tinyxml-2
, foonathan_memory
}:

stdenv.mkDerivation {
  pname = "fastdds";
  version = "2.12.2";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Fast-DDS";
    rev = "v2.12.2";
    hash = "sha256-8H0ENFqA+gZTr1F8J1YrS6gC3xF66mAA/E4AF0E3j08=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ fastcdr asio tinyxml-2 foonathan_memory ];

  env.NIX_CFLAGS_COMPILE = lib.concatStringsSep " " [
    "-Wno-error=template-id-cdtor"
  ];

  postPatch = ''
    echo "#include <cstdint>" > xtempfile
    cat xtempfile src/cpp/statistics/types/typesv1.cxx > ytempfile
    mv ytempfile src/cpp/statistics/types/typesv1.cxx
    rm xtempfile
  '';
}
