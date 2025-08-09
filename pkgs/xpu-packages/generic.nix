{
  lib,
  autoPatchelfHook,
  callPackage,
  fetchurl,
  stdenv,
  rpmextract,
  rsync,
  zlib,

  pname,
  version,

  # List of string-typed dependencies.
  deps,

  # List of derivations that must be merged.
  components,
}:

let
  srcs = map (component: fetchurl { inherit (component) url sha256; }) components;
in
stdenv.mkDerivation rec {
  inherit pname version srcs;

  nativeBuildInputs = [
    autoPatchelfHook
    rpmextract
    rsync
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    stdenv.cc.cc.libgcc
    # Add zlib for libz.so.1 dependency
    zlib
  ];

  # Extract RPM packages using rpmextract
  unpackPhase = ''
    for src in $srcs; do
      rpmextract "$src"
    done
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out

    # Check if opt/intel exists and copy content
    if [ -d "opt/intel" ]; then
      cp -rT opt/intel $out
    elif [ -d "opt" ]; then
      cp -rT opt $out
    else
      # Fallback: copy everything if no opt directory found
      cp -r . $out/
    fi

    runHook postInstall
  '';

  # Stripping the binaries from the oneAPI packages might break them
  dontStrip = true;

  # Don't check for broken symlinks - Intel packages often have complex internal symlink structures
  preFixup = ''
    # Remove broken symlinks that point to Intel's "latest" structure
    find $out -type l ! -exec test -e {} \; -delete 2>/dev/null || true
  '';

  autoPatchelfIgnoreMissingDeps = [
    # oneAPI specific libraries that should come from driver/runtime
    "libOpenCL.so.1"
    "libze_loader.so.1"
    "libtbbmalloc.so.2"
    "libtbb.so.12"
    "libsycl.so.8" # Intel SYCL runtime library
    "libmkl_sycl_blas.so.5"
    "libhwloc.so.15" # Hardware Locality library
    "libhwloc.so.5" # Hardware Locality library

    # Intel math and compiler libraries
    "libimf.so" # Intel Math Functions library
    "libsvml.so" # Intel Short Vector Math Library
    "libirng.so" # Intel Random Number Generator library
    "libintlc.so.5" # Intel Compiler library
    "libur_loader.so.0" # Unified Runtime loader
    "libffi.so" # Foreign Function Interface library
    "libumf.so.0" # Unified Memory Framework
    "libxptifw.so" # Intel XPU Profiling and Tracing Interface

    # MKL libraries (provided by other MKL packages or cross-dependencies)
    "libmkl_core.so.2" # MKL Core library
    "libmkl_intel_lp64.so.2" # MKL Intel LP64 interface
    "libmkl_intel_thread.so.2" # MKL Intel threading layer
    "libmkl_sequential.so.2" # MKL sequential layer

    # MPI libraries (not part of oneAPI, used by benchmarks only)
    "libmpi.so.12" # Message Passing Interface library
    "libmpicxx.so.12" # MPI C++ bindings
    "libmpifort.so.12" # MPI Fortran bindings
    "libiomp5.so" # OMP library

    # System libraries that might not be available
    "libpython3.6m.so.1.0"
    "libpython3.7m.so.1.0"
    "libpython3.8.so.1.0"
    "libpython3.9.so.1.0"
    "libonnxruntime.1.12.22.721.so"
    "libelf.so.1"
  ];

  meta = with lib; {
    description = "Intel oneAPI package: ${pname}";
    homepage = "https://software.intel.com/oneapi";
    platforms = platforms.linux;
    license = licenses.unfree;
  };
}
