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
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Fast-DDS";
    rev = "v3.1.0";
    hash = "sha256-YUAIuIQapa+SzYKE+/GFYMI4tjBrldmojHkYHim0mFw=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ fastcdr asio tinyxml-2 foonathan_memory ];

  env.NIX_CFLAGS_COMPILE = lib.concatStringsSep " " [
    "-Wno-error=template-id-cdtor"
  ];
}
