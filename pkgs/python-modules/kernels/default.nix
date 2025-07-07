{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  huggingface-hub,
  torch,
}:

buildPythonPackage rec {
  pname = "kernels";
  version = "0.7.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-uq3ZYB59OyYC8P73RZ8pa9yBFRkvg1JZcoJLVQOliZg=";
  };

  pyproject = true;

  build-system = [ setuptools ];

  dependencies = [
    huggingface-hub
    torch
  ];

  pythonImportsCheck = [ "kernels" ];

  meta = {
    description = "Fetch compute kernels from the hub";
  };
}
