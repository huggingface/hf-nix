{
  config,
  lib,
  stdenv,
  buildPythonPackage,
  fetchurl,

  cudaSupport ? config.cudaSupport,
  rocmSupport ? config.rocmSupport,
  tritonSupport ? (!stdenv.hostPlatform.isDarwin),
  xpuSupport ? (config.xpuSupport or false),

  # Navtive build inputs
  autoAddDriverRunpath,
  autoPatchelfHook,
  python,

  # Build inputs
  cudaPackages,
  rocmPackages,
  xpuPackages,

  pkgs, # For zstd, we do not want the Python package.
  bzip2,
  xz,
  zlib,

  # Python dependencies
  filelock,
  jinja2,
  networkx,
  numpy,
  pyyaml,
  requests,
  setuptools,
  sympy,
  triton,
  triton-cuda,
  triton-rocm,
  typing-extensions,

  url,
  hash,
  version,
  # Remove, needed for compat.
  cxx11Abi ? true,
}:
let

  tritonEffective =
    if cudaSupport then
      triton-cuda
    else if rocmSupport then
      triton-rocm
    else if xpuSupport then
      python.pkgs.triton-xpu_2_8
    else
      triton;

  archs = (import ../archs.nix).${lib.versions.majorMinor version};

  supportedTorchCudaCapabilities =
    let
      inherit (archs) capsPerCudaVersion;
      real = capsPerCudaVersion."${lib.versions.majorMinor cudaPackages.cudaMajorMinorVersion}";
      ptx = lib.map (x: "${x}+PTX") real;
    in
    real ++ ptx;
  supportedCudaCapabilities = lib.intersectLists cudaPackages.flags.cudaCapabilities supportedTorchCudaCapabilities;
  inherit (archs) supportedTorchRocmArchs;
in
buildPythonPackage {
  pname = "torch";
  inherit version;

  format = "wheel";

  src = fetchurl {
    inherit url hash;
  };

  nativeBuildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [
      autoPatchelfHook
    ]
    ++ lib.optionals cudaSupport [ autoAddDriverRunpath ];

  buildInputs =
    lib.optionals cudaSupport (
      with cudaPackages;
      [
        # Use lib output to avoid libcuda.so.1 stub getting used.
        cuda_cudart.lib
        cuda_cupti
        cuda_nvrtc
        cudnn
        cusparselt
        libcublas
        libcufft
        libcufile
        libcurand
        libcusolver
        libcusparse
        nccl
      ]
    )
    ++ lib.optionals rocmSupport ([
      bzip2
      xz
      zlib
      pkgs.zstd
    ])
    ++ lib.optionals xpuSupport (
      with xpuPackages;
      [
        intel-oneapi-ccl
        intel-oneapi-compiler-dpcpp-cpp-runtime
        intel-oneapi-compiler-shared-runtime
        intel-oneapi-mkl-core
        intel-oneapi-mkl-sycl-blas
        intel-oneapi-mkl-sycl-dft
        intel-oneapi-mkl-sycl-lapack
        intel-oneapi-mpi
        intel-pti
      ]
    );

  dependencies = [
    filelock
    jinja2
    networkx
    numpy
    pyyaml
    requests
    setuptools
    sympy
    typing-extensions
  ]
  ++ lib.optionals tritonSupport [
    tritonEffective
  ];

  postInstall =
    lib.optionalString rocmSupport ''
      ln -sf "$out/${python.sitePackages}/torch/lib/librocblas.so" "$out/${python.sitePackages}/torch/lib/librocblas.so.4"
    ''
    + lib.optionalString (xpuSupport && (lib.versions.majorMinor version) == "2.7") ''
      patchelf --replace-needed libpti_view.so.0.10 libpti_view.so $out/${python.sitePackages}/torch/lib/libtorch_cpu.so
    '';

  autoPatchelfIgnoreMissingDeps = lib.optionals stdenv.hostPlatform.isLinux [
    "libcuda.so.1"
  ];

  # See https://github.com/NixOS/nixpkgs/issues/296179
  #
  # This is a quick hack to add `libnvrtc` to the runpath so that torch can find
  # it when it is needed at runtime.
  extraRunpaths = lib.optionals cudaSupport [ "${lib.getLib cudaPackages.cuda_nvrtc}/lib" ];
  postPhases = lib.optionals stdenv.hostPlatform.isLinux [ "postPatchelfPhase" ];
  postPatchelfPhase = ''
    while IFS= read -r -d $'\0' elf ; do
      for extra in $extraRunpaths ; do
        echo patchelf "$elf" --add-rpath "$extra" >&2
        patchelf "$elf" --add-rpath "$extra"
      done
    done < <(
      find "''${!outputLib}" "$out" -type f -iname '*.so' -print0
    )
  '';

  dontStrip = true;

  pythonImportsCheck = [ "torch" ];

  passthru = {
    inherit
      cudaSupport
      cudaPackages
      cxx11Abi
      rocmSupport
      rocmPackages
      xpuSupport
      xpuPackages
      ;

    cudaCapabilities = if cudaSupport then supportedCudaCapabilities else [ ];
    rocmArchs = if rocmSupport then supportedTorchRocmArchs else [ ];
  };

  meta = with lib; {
    description = "PyTorch: Tensors and Dynamic neural networks in Python with strong GPU acceleration";
    homepage = "https://pytorch.org/";
    license = lib.licenses.bsd3;
  };
}
