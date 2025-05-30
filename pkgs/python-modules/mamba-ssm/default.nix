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
  which,
  cudaPackages,
  torch,
  einops,
  transformers,
}:

buildPythonPackage rec {
  pname = "mamba";
  version = "2.2.2";

  src = fetchFromGitHub {
    owner = "state-spaces";
    repo = pname;
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-R702JjM3AGk7upN7GkNK8u1q4ekMK9fYQkpO6Re45Ng=";
  };

  stdenv = cudaPackages.backendStdenv;

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
    torch
    packaging
    einops
    torch
    transformers
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

  pythonImportsCheck = [ "mamba_ssm" ];

  meta = with lib; {
    description = "Mamba selective space state model";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
