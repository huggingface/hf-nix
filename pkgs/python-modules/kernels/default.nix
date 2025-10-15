{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  huggingface-hub,
}:

buildPythonPackage rec {
  pname = "kernels";
  version = "0.10.3";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-MJciOc9jwOmp3ULCowNxj0cXnScJU/S7tj4n3xU4UHQ=";
  };

  pyproject = true;

  build-system = [ setuptools ];

  dependencies = [
    huggingface-hub
  ];

  pythonImportsCheck = [ "kernels" ];

  meta = {
    description = "Fetch compute kernels from the hub";
  };
}
