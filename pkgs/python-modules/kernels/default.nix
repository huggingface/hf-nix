{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  huggingface-hub,
}:

buildPythonPackage rec {
  pname = "kernels";
  version = "0.10.4";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-2+GyKEEGU7mMriXsggmSYWTGIhXwwKG681QnhCN3i1A=";
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
