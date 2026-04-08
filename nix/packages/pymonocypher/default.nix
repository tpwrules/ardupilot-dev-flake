# Pinned to 3.1.3.2 to match the version required by the signing scripts.
{ lib, fetchPypi, buildPythonPackage, setuptools }:

buildPythonPackage rec {
  pname = "pymonocypher";
  version = "3.1.3.2";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-s+ZAbWQjCoMnjLi+mP6wjCPfaowAzzwxccWydXte2ek=";
  };

  nativeBuildInputs = [ setuptools ];

  pythonImportsCheck = [ "monocypher" ];

  meta = with lib; {
    homepage = "https://github.com/jetperch/pymonocypher";
    description = "Python bindings for Monocypher crypto library";
    license = licenses.bsd2;
    maintainers = [ ];
  };
}
