{
  lib,
  stdenv,
  fetchFromGitHub,
  buildPythonPackage,
  autoAddDriverRunpath,
  cmake,
  git,
  ninja,
  packaging,
  psutil,
  setuptools,
  which,
  cudaPackages,
  fastparquet,
  pandas,
  torch,
  safetensors,
  sentencepiece,
  tokenizers,
  regex,
  rich,
  websockets,
}:

buildPythonPackage rec {
  pname = "exllamav2";
  version = "0.1.8";

  src = fetchFromGitHub {
    owner = "turboderp";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-w5LDZi/HyWodqlV3ZUabR5cEBzQMaSmHY5rVVQeMXCs=";
  };

  stdenv = cudaPackages.backendStdenv;

  pyproject = true;

  build-system = [ setuptools ];

  buildInputs = with cudaPackages; [
    cuda_cccl
    cuda_cudart
    libcublas
    libcusolver
    libcusparse
    libcurand
  ];

  nativeBuildInputs = [
    autoAddDriverRunpath
    cmake
    ninja
    which
  ];

  dependencies = [
    fastparquet
    pandas
    safetensors
    sentencepiece
    tokenizers
    torch
    regex
    rich
    websockets
  ];

  env = {
    CUDA_HOME = lib.getDev cudaPackages.cuda_nvcc;
    TORCH_CUDA_ARCH_LIST = lib.concatStringsSep ";" torch.cudaCapabilities;
  };

  propagatedBuildInputs = [ torch ];

  # cmake/ninja are used for parallel builds, but we don't want the
  # cmake configure hook to kick in.
  dontUseCmakeConfigure = true;

  # We don't have any tests in this package (yet).
  doCheck = false;

  preBuild = ''
    export MAX_JOBS=$NIX_BUILD_CORES
  '';

  # pythonImportsCheck = [ "exllamav2" ];

  meta = with lib; {
    description = "Inference library for running local LLMs on modern consumer GPUs";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
