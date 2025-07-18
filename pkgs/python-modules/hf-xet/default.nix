{
  lib,
  stdenv,
  fetchFromGitHub,
  buildPythonPackage,
  rustPlatform,
  perl,
  openssl,
  pkg-config,
}:

buildPythonPackage rec {
  pname = "hf-xet";
  version = "1.1.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "huggingface";
    repo = "xet-core";
    rev = "v${version}";
    hash = "sha256-udjZcXTH+Mc4Gvj6bSPv1xi4MyXrLeCYav+7CzKWyhY=";
  };

  sourceRoot = "${src.name}/hf_xet";

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    sourceRoot = "${src.name}/hf_xet";
    hash = "sha256-PTzYubJHFvhq6T3314R4aqBAJlwehOqF7SbpLu4Jo6E=";
  };

  build-system = [
    pkg-config
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  buildInputs = [ openssl.dev ];

  meta = with lib; {
    description = "Speed up file transfers with Hugging Face Hub";
    license = licenses.asl20;
  };
}
