{dpcppVersion, ptiVersion, mklVersion, tbbVersion, ompVersion}:

final: prev: {
  # Intel oneAPI development environment for PyTorch compilation
  oneapi-torch-dev = final.callPackage (
    {
      lib,
      stdenv,
      rsync,
    }:
    let
      # Build only the most essential Intel packages for PyTorch
      essentialIntelPackages = [
        # Core DPC++ compiler package and its dependencies
        final."intel-oneapi-dpcpp-cpp-${dpcppVersion}"
        # Compiler runtime and shared components
        final."intel-oneapi-compiler-dpcpp-cpp-runtime-${dpcppVersion}"
        final."intel-oneapi-compiler-shared-${dpcppVersion}"
        final."intel-oneapi-compiler-shared-runtime-${dpcppVersion}"
        final."intel-oneapi-compiler-shared-common-${dpcppVersion}"
        final."intel-oneapi-compiler-dpcpp-cpp-common-${dpcppVersion}"
        # MKL for math operations - most important for PyTorch
        final."intel-oneapi-mkl-classic-include-${mklVersion}"
        final."intel-oneapi-mkl-cluster-${mklVersion}"
        final."intel-oneapi-mkl-cluster-devel-${mklVersion}"
        final."intel-oneapi-mkl-core-${mklVersion}"
        final."intel-oneapi-mkl-devel-${mklVersion}"
        final."intel-oneapi-mkl-core-devel-${mklVersion}"
        final."intel-oneapi-mkl-sycl-${mklVersion}"
        final."intel-oneapi-mkl-sycl-devel-${mklVersion}"
        final."intel-oneapi-mkl-sycl-include-${mklVersion}"
        final."intel-oneapi-mkl-sycl-blas-${mklVersion}"
        final."intel-oneapi-mkl-sycl-lapack-${mklVersion}"
        final."intel-oneapi-mkl-sycl-dft-${mklVersion}"
        final."intel-oneapi-mkl-sycl-data-fitting-${mklVersion}"
        final."intel-oneapi-mkl-sycl-rng-${mklVersion}"
        final."intel-oneapi-mkl-sycl-sparse-${mklVersion}"
        final."intel-oneapi-mkl-sycl-stats-${mklVersion}"
        final."intel-oneapi-mkl-sycl-vm-${mklVersion}"
        # Common infrastructure packages
        #final."intel-oneapi-common-licensing-2025.2"
        final.intel-oneapi-common-vars
        # TBB for threading
        final."intel-oneapi-tbb-${tbbVersion}"
        final."intel-oneapi-tbb-devel-${tbbVersion}"
        # OpenMP
        final."intel-oneapi-openmp-${ompVersion}"
        # PTI (Profiling and Tracing Interface) - required for PyTorch compilation
        final."intel-pti-dev-${ptiVersion}"
        final."intel-pti-${ptiVersion}"
        final."intel-oneapi-vtune"
      ];

    in
    stdenv.mkDerivation {
      name = "oneapi-torch-dev-${dpcppVersion}";
      nativeBuildInputs = [rsync];

      buildCommand = ''
        # Merge all top-level directories from every package into $out using rsync
        for pkg in ${lib.concatStringsSep " " essentialIntelPackages}; do
          for subdir in $(ls "$pkg"); do
            if [ -d "$pkg/$subdir" ]; then
              mkdir -p "$out/$subdir"
              rsync -a "$pkg/$subdir/" "$out/$subdir/"
            fi
          done
        done

        # Create 'latest' symlink in compiler,mkl,pti pointing to the current version
        chmod +w $out/oneapi/compiler
        ln -sf $out/oneapi/compiler/${dpcppVersion} $out/oneapi/compiler/latest

        chmod +w $out/oneapi/mkl
        ln -sf $out/oneapi/mkl/${mklVersion} $out/oneapi/mkl/latest

        chmod +w $out/oneapi/pti
        ln -sf $out/oneapi/pti/${ptiVersion} $out/oneapi/pti/latest

        chmod +w $out/oneapi/tbb
        ln -sf $out/oneapi/tbb/${tbbVersion} $out/oneapi/tbb/latest

        chmod +w $out/oneapi/vtune
        ln -sf $out/oneapi/vtune/* $out/oneapi/vtune/latest

        pti_lib_dir="$out/oneapi/pti/latest/lib"
        chmod +w $pti_lib_dir
        if [ ! -e "$pti_lib_dir/libpti_view.so" ]; then
          real_pti_view=$(ls "$pti_lib_dir"/libpti_view.so.* 2>/dev/null | head -n1)
          if [ -n "$real_pti_view" ]; then
            ln -sf "$(basename "$real_pti_view")" "$pti_lib_dir/libpti_view.so"
          fi
        fi

        igc_dir="$out/oneapi/vtune/latest/bin64/gma/GTPin/Profilers/ocloc/Bin/intel64"
        chmod +w $igc_dir
        if [ -f "$igc_dir/libigc.so" ] && [ ! -e "$igc_dir/libigc.so.1" ]; then
          ln -sf libigc.so "$igc_dir/libigc.so.1"
        fi

      '';
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
  ) { };

}
