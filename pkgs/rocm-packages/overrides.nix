let
  applyOverrides =
    overrides: final: prev:
    prev.lib.mapAttrs (name: value: prev.${name}.overrideAttrs (final.callPackage value { })) overrides;
in
applyOverrides {
  comgr =
    {
      ncurses,
      zlib,
      zstd,
    }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [
        ncurses
        zlib
        zstd
      ];
    };

  hipblas =
    {
      lib,
      hipblas-common-devel ? null,
    }:
    prevAttrs: {
      # Only available starting ROCm 6.3.
      propagatedBuildInputs =
        prevAttrs.buildInputs ++ lib.optionals (hipblas-common-devel != null) [ hipblas-common-devel ];
    };

  hipblaslt =
    { hip-runtime-amd }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [ hip-runtime-amd ];
    };

  hipify-clang =
    {
      ncurses,
      zlib,
      zstd,
    }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [
        ncurses
        zlib
        zstd
      ];
    };

  hiprand =
    { hip-runtime-amd, rocrand }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [
        hip-runtime-amd
        rocrand
      ];
    };

  openmp-extras-devel =
    { ncurses, zlib }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [
        ncurses
        zlib
      ];
    };

  openmp-extras-runtime =
    { rocm-llvm, libffi_3_2 }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [
        libffi_3_2
        rocm-llvm
      ];
      # Can we change rocm-llvm to pick these up?
      installPhase = (prevAttrs.installPhase or "") + ''
        addAutoPatchelfSearchPath ${rocm-llvm}/lib/llvm/lib
      '';
    };

  hipsolver =
    {
      lib,
      suitesparse,
      suitesparse_4_4,
    }:
    prevAttrs:
    let
      effectiveSuitesparse =
        # Remove this conditional when removing ROCm 6.2.
        if lib.versionAtLeast prevAttrs.version "2.3.0" then suitesparse else suitesparse_4_4;
    in
    {
      buildInputs = prevAttrs.buildInputs ++ [
        effectiveSuitesparse
      ];
    };

  hsa-rocr =
    {
      elfutils,
      libdrm,
      numactl,
    }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [
        elfutils
        libdrm
        numactl
      ];
    };

  rocfft =
    { hip-runtime-amd }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [ hip-runtime-amd ];
    };

  rocm-llvm =
    {
      libxml2,
      ncurses,
      zlib,
      zstd,
    }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [
        libxml2
        ncurses
        zlib
        zstd
      ];

      installPhase = (prevAttrs.installPhase or "") + ''
        # Dead symlink(s).
        chmod -R +w $out/lib
        rm -f $out/lib/llvm/bin/flang
      '';
    };

  rocminfo =
    { python3 }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [ python3 ];
    };

  rocrand =
    { hip-runtime-amd }:
    prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ [ hip-runtime-amd ];
    };

  roctracer =
    { comgr, hsa-rocr }:
    prevAttr: {
      buildInputs = prevAttr.buildInputs ++ [
        comgr
        hsa-rocr
      ];
    };
}
