{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "mktestdocs";
  version = "0.2.5";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "koaning";
    repo = pname;
    # Version was not tagged, so use the exact commit for now. We don't
    # fetch from PyPI, because the PyPI source does not have all the test
    # files.
    # rev = "v${version}";
    rev = "f3fab756ce0b5f32b0676073e7546893708eaeca";
    hash = "sha256-OiOkU/qfxeLbCT1QywA1rGSwe9Ja8tENTmBo93vo0vc=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "mktestdocs" ];

  meta = with lib; {
    description = "Run pytest against markdown files/docstrings";
    homepage = "https://github.com/koaning/mktestdocs";
    license = licenses.asl20;
  };
}
