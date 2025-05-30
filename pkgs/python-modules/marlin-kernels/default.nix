{
  lib,
  stdenv,
  fetchFromGitHub,
  buildPythonPackage,
  autoAddDriverRunpath,
  cmake,
  ninja,
  which,
  packaging,
  setuptools,
  wheel,
  cudaPackages,
  torch,
}:

let
  cutlass = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "cutlass";
    rev = "refs/tags/v3.6.0";
    hash = "sha256-FbMVqR4eZyum5w4Dj5qJgBPOS66sTem/qKZjYIK/7sg=";
  };
in
buildPythonPackage rec {
  pname = "marlin-kernels";
  version = "0.3.7";

  src = fetchFromGitHub {
    owner = "danieldk";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-xh4EnjFSQ3VrGGOsZOMbmIwfFmY6N/KghjmXMTn4tfc=";
  };

  patches = [
    ./setup.py-nix-support-respect-cmakeFlags.patch
  ];

  stdenv = cudaPackages.backendStdenv;

  nativeBuildInputs = with cudaPackages; [
    autoAddDriverRunpath
    cmake
    cuda_nvcc
    ninja
    which
  ];

  build-system = [
    packaging
    setuptools
    wheel
  ];

  buildInputs = with cudaPackages; [
    cuda_cccl
    cuda_cudart
    cuda_nvtx
    libcublas
    libcusolver
    libcusparse
  ];

  env = {
    CUDA_HOME = "${lib.getDev cudaPackages.cuda_nvcc}";
    # Build time is largely determined by a few kernels. So opt for parallelism
    # for every capability.
    NVCC_THREADS = builtins.length torch.cudaCapabilities;
    TORCH_CUDA_ARCH_LIST = lib.concatStringsSep ";" torch.cudaCapabilities;
  };

  propagatedBuildInputs = [ torch ];

  # cmake/ninja are used for parallel builds, but we don't want the
  # cmake configure hook to kick in.
  dontUseCmakeConfigure = true;

  cmakeFlags = [ (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_CUTLASS" "${lib.getDev cutlass}") ];

  # We don't have any tests in this package (yet).
  doCheck = false;

  pythonImportsCheck = [ "marlin_kernels" ];

  meta = with lib; {
    description = "Marlin quantization kernels";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
