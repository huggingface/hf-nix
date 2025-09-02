{
  lib,
  stdenv,

  makeSetupHook,
  makeWrapper,
  markForXpuRootHook,
  rsync,
  writeShellScriptBin,

  gcc,
  intel-oneapi-dpcpp-cpp,
  intel-oneapi-compiler-dpcpp-cpp-runtime,
  intel-oneapi-compiler-shared,
  intel-oneapi-compiler-shared-runtime,
  intel-oneapi-compiler-shared-common,
  intel-oneapi-compiler-dpcpp-cpp-common,
  intel-oneapi-mkl-classic-include,
  intel-oneapi-mkl-core,
  intel-oneapi-mkl-devel,
  intel-oneapi-mkl-sycl,
  intel-oneapi-mkl-sycl-include,
  intel-oneapi-mkl-sycl-blas,
  intel-oneapi-mkl-sycl-lapack,
  intel-oneapi-mkl-sycl-dft,
  intel-oneapi-mkl-sycl-data-fitting,
  intel-oneapi-mkl-sycl-rng,
  intel-oneapi-mkl-sycl-sparse,
  intel-oneapi-mkl-sycl-stats,
  intel-oneapi-mkl-sycl-vm,
  intel-oneapi-common-vars,
  intel-oneapi-tbb,
  intel-oneapi-openmp,
  intel-pti-dev,
  intel-pti,

}:

let
  # Build only the most essential Intel packages for PyTorch
  essentialIntelPackages = [
    # Core DPC++ compiler package and its dependencies
    intel-oneapi-dpcpp-cpp
    # Compiler runtime and shared components
    intel-oneapi-compiler-dpcpp-cpp-runtime
    intel-oneapi-compiler-shared
    intel-oneapi-compiler-shared-runtime
    intel-oneapi-compiler-shared-common
    intel-oneapi-compiler-dpcpp-cpp-common
    # MKL for math operations - most important for PyTorch
    intel-oneapi-mkl-classic-include
    intel-oneapi-mkl-core
    intel-oneapi-mkl-devel
    intel-oneapi-mkl-sycl
    intel-oneapi-mkl-sycl-include
    intel-oneapi-mkl-sycl-blas
    intel-oneapi-mkl-sycl-lapack
    intel-oneapi-mkl-sycl-dft
    intel-oneapi-mkl-sycl-data-fitting
    intel-oneapi-mkl-sycl-rng
    intel-oneapi-mkl-sycl-sparse
    intel-oneapi-mkl-sycl-stats
    intel-oneapi-mkl-sycl-vm
    # Common infrastructure packages
    #final."intel-oneapi-common-licensing-2025.2"
    intel-oneapi-common-vars
    # TBB for threading
    intel-oneapi-tbb
    # OpenMP
    intel-oneapi-openmp
    # PTI (Profiling and Tracing Interface) - required for PyTorch compilation
    intel-pti-dev
    intel-pti
  ];

  hostCompiler = 
    writeShellScriptBin "g++" ''
      exec ${gcc.cc}/bin/g++ \
        -nostdinc  \
        -isysroot ${stdenv.cc.libc_dev} \
        -isystem${stdenv.cc.libc_dev}/include \
        -I${gcc.cc}/include/c++/${gcc.version} \
        -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu \
        -I${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version}/include \
        "$@"
    '';
in
stdenv.mkDerivation {
  pname = "oneapi-torch-dev";
  version = intel-oneapi-dpcpp-cpp.version;

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
    markForXpuRootHook
    rsync
  ];

  installPhase =
    let
      wrapperArgs = [
        "--add-flags -B${stdenv.cc.libc}/lib"
        "--add-flags -B${placeholder "out"}/lib/crt"
        "--add-flags '-isysroot ${stdenv.cc.libc_dev}'"
        #"--add-flags '-isystem ${placeholder "out"}/lib/clang/21/include'"
        "--add-flags '-isystem ${stdenv.cc.libc_dev}/include'"
        "--add-flags -I${gcc.cc}/include/c++/${gcc.version}"
        "--add-flags -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu"
        "--set NIX_LIBGCC_S_PATH ${stdenv.cc.cc.lib}/lib"
        "--add-flags -L${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.uname.processor}-unknown-linux-gnu/${stdenv.cc.cc.version}"
        "--add-flags -L${lib.getLib stdenv.cc.cc}/lib"
        #"--add-flags -L${stdenv.cc.cc.libgcc}/lib"
      ];
    in
    ''
      # Merge all top-level directories from every package into $out using rsync
      for pkg in ${lib.concatStringsSep " " essentialIntelPackages}; do
        rsync -a --exclude=nix-support $pkg/ $out/
      done

      chmod -R u+w $out

      wrapProgram $out/bin/icx ${lib.concatStringsSep " " wrapperArgs}
      wrapProgram $out/bin/icpx ${lib.concatStringsSep " " wrapperArgs}

      #mkdir -p $out/nix-support
      #echo 'export SYCL_ROOT="'$out'/oneapi/compiler/latest"' >> $out/nix-support/setup-hook
      #echo 'export Pti_DIR="'$out'/oneapi/pti/latest/lib/cmake/pti"' >> $out/nix-support/setup-hook
      #echo 'export MKLROOT="'$out'/oneapi/mkl/latest"' >> $out/nix-support/setup-hook
      #echo 'export SYCL_EXTRA_INCLUDE_DIRS="${gcc.cc}/include/c++/${gcc.version} ${stdenv.cc.libc_dev}/include ${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu"' >> $out/nix-support/setup-hook
      #echo 'export CMAKE_CXX_FLAGS="-I${gcc.cc}/include/c++/${gcc.version} -I${stdenv.cc.libc_dev}/include -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu -B${stdenv.cc.libc}/lib -B'$out'/oneapi/compiler/latest/lib/crt -L${stdenv.cc}/lib -L${stdenv.cc}/lib64 -L${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version} -L${stdenv.cc.cc.lib}/lib"' >> $out/nix-support/setup-hook
      #chmod 0444 $out/nix-support/setup-hook
    '';

  dontStrip = true;

  # We need to pass through the hostCompiler to oneDNN and Torch. Ideally,
  # we would do this in the icx/icpx wrapping above. However, Torch etc. pass
  # the sycl-host-compiler option, so we would have to filter out the flag
  # to make it work.
  passthru = { inherit hostCompiler; };

  meta = with lib; {
    description = "Intel oneAPI development environment for PyTorch (copied files)";
    longDescription = ''
      A development package for PyTorch compilation with Intel optimizations.
      Uses copied files instead of symlinks to avoid path issues.
    '';
    license = licenses.free;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
