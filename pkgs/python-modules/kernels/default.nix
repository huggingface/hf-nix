{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  huggingface-hub,
}:

buildPythonPackage rec {
  pname = "kernels";
  version = "0.10.2";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-0pDYJjmqPaCryaXjvYZ6YkR5cchqN7snc4jQ/a3Le24=";
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
