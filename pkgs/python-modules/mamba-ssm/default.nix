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
  setuptools,
  which,
  cudaPackages,
  einops,
  torch,
  transformers,
  triton,
}:

buildPythonPackage rec {
  pname = "mamba";
  version = "2.2.4";

  src = fetchFromGitHub {
    owner = "state-spaces";
    repo = pname;
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-noATHU9OiLzWc6rwiyL0wD9Q85Y/3bVpilKdUT9h0kU=";
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
  ];

  nativeBuildInputs = [
    autoAddDriverRunpath
    cmake
    ninja
    which
  ];

  dependencies = [
    packaging
    einops
    torch
    transformers
    triton
  ];

  env = {
    CUDA_HOME = lib.getDev cudaPackages.cuda_nvcc;
    TORCH_CUDA_ARCH_LIST = lib.concatStringsSep ";" torch.cudaCapabilities;
    MAMBA_FORCE_BUILD = "TRUE";
  };

  # cmake/ninja are used for parallel builds, but we don't want the
  # cmake configure hook to kick in.
  dontUseCmakeConfigure = true;

  # We don't have any tests in this package (yet).
  doCheck = false;

  preBuild = ''
    export MAX_JOBS=$NIX_BUILD_CORES
  '';

  # Import seems to require a GPU.
  #pythonImportsCheck = [ "mamba_ssm" ];

  meta = with lib; {
    description = "Mamba selective space state model";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
