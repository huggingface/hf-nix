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
  which,
  cudaPackages,
  torch,
}:

buildPythonPackage rec {
  pname = "flash-attn-rotary";
  version = "2.6.3";

  src = fetchFromGitHub {
    owner = "Dao-AILab";
    repo = "flash-attention";
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-ht234geMnOH0xKjhBOCXrzwYZuBFPvJMCZ9P8Vlpxcs=";
  };

  sourceRoot = "${src.name}/csrc/rotary";

  stdenv = cudaPackages.backendStdenv;

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
    git
    ninja
    packaging
    which
  ];

  env = {
    CUDA_HOME = "${lib.getDev cudaPackages.cuda_nvcc}";
    FLASH_ATTENTION_FORCE_BUILD = "TRUE";
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

  pythonImportsCheck = [ "rotary_emb" ];

  meta = with lib; {
    description = "Marlin quantization kernels";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
