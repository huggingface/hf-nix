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
  einops,
  torch,
}:

buildPythonPackage rec {
  pname = "flash-attn-v1";
  version = "dev";

  src = fetchFromGitHub {
    owner = "HazyResearch";
    repo = "flash-attention";
    rev = "3a9bfd076f98746c73362328958dbc68d145fbec";
    fetchSubmodules = true;
    hash = "sha256-QKWf34eaAkcZUcemHiNsSPKeGoXktorGVJVpt8Cva2Y=";
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

  dependencies = [
    einops
  ];

  nativeBuildInputs = [
    autoAddDriverRunpath
    cmake
    git
    ninja
    packaging
    which
  ];

  env = {
    CUDA_HOME = "${lib.getDev cudaPackages.cuda_nvcc}";
    FORE_CUDA = 1;
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

  pythonImportsCheck = [ "flash_attn" ];

  meta = with lib; {
    description = "Flash attention";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
