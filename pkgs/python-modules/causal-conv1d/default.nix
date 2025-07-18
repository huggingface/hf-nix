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
  torch,
}:

buildPythonPackage rec {
  pname = "causal-conv1d";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "Dao-AILab";
    repo = pname;
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-p5x5u3zEmEMN3mWd88o3jmcpKUnovTvn7I9jIOj/ie0=";
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
    psutil
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
  ];

  env = {
    CUDA_HOME = lib.getDev cudaPackages.cuda_nvcc;
    TORCH_CUDA_ARCH_LIST = lib.concatStringsSep ";" torch.cudaCapabilities;
    CAUSAL_CONV1D_FORCE_BUILD = "TRUE";
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

  pythonImportsCheck = [ "causal_conv1d" ];

  meta = with lib; {
    description = "Causal 1D convolution";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
