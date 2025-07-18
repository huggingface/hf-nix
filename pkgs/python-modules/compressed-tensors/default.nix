{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pydantic,
  torch,
  transformers,
}:

buildPythonPackage rec {
  pname = "compressed-tensors";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "neuralmagic";
    repo = pname;
    rev = version;
    hash = "sha256-65QqVLz3ITz1mqn1gK5MbN4BN3jzwsYsZbLscs57ZIM=";
  };

  pyproject = true;

  build-system = [ setuptools ];

  dependencies = [
    torch
    pydantic
    transformers
  ];

  pythonImportsCheck = [ "compressed_tensors" ];

  meta = {
    description = "A safetensors extension to efficiently store sparse quantized tensors on disk";
    homepage = "https://github.com/neuralmagic/compressed-tensors";
    license = lib.licenses.asl20;
  };
}
