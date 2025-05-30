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
  pname = "awq-inference-engine";
  version = "0.1.0-dev";

  src = fetchFromGitHub {
    owner = "huggingface";
    repo = "llm-awq";
    rev = "bd1dc2d5254345cc76ab71894651fb821275bdd4";
    hash = "sha256-vNe8Nhnzrux3ysi+1d2E8CuJJ3uPxpATdSTlywC6p+s=";
  };

  sourceRoot = "${src.name}/awq/kernels";

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
  ];

  env =
    let
      # Only supports compute capability 8.0 or later.
      cudaCapabilities = lib.filter (v: lib.versionAtLeast v "8.0") torch.cudaCapabilities;
    in
    {
      CUDA_HOME = lib.getDev cudaPackages.cuda_nvcc;
      TORCH_CUDA_ARCH_LIST = lib.concatStringsSep ";" cudaCapabilities;
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

  pythonImportsCheck = [ "awq_inference_engine" ];

  meta = with lib; {
    description = "Activation-aware Weight Quantization (AWQ) kernels";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
