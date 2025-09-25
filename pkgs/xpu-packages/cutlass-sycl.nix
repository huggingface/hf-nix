{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  setupXpuHook,
  oneapi-torch-dev,
  python3,
  ocloc,
}:

let
  dpcppVersion = oneapi-torch-dev.version;
  cutlassVersions = {
    "2025.0" = {
      version = "3.9-0.2";
      hash = "sha256-4/Wo5iTN4d4uLJF6+S/mQlpU8KSGOXwtIRyl2PaV/UA=";
    };
    "2025.1" = {
      version = "3.9-0.3";
      hash = "sha256-FLmTseMw31txptQkvWaN03xoaLzIbQz2Ip1xtCKH3ZE=";
    };
    "2025.2" = {
      #TODO, need to update once new tag is released
      version = "3.9-0.3";
      hash = "sha256-FLmTseMw31txptQkvWaN03xoaLzIbQz2Ip1xtCKH3ZE=";
    };
  };
  cutlassVersion =
    cutlassVersions.${lib.versions.majorMinor dpcppVersion}
    or (throw "Unsupported DPC++ version: ${dpcppVersion}");
in

stdenv.mkDerivation rec {
  pname = "cutlass-sycl";
  inherit (cutlassVersion) version;

  src = fetchFromGitHub {
    owner = "intel";
    repo = "cutlass-sycl";
    tag = "v${cutlassVersion.version}";
    inherit (cutlassVersion) hash;
  };

  nativeBuildInputs = [
    cmake
    ninja
    setupXpuHook
    oneapi-torch-dev
    python3
    ocloc
  ];

  cmakeFlags = [
    "-DCMAKE_C_COMPILER=icx"
    "-DCMAKE_CXX_COMPILER=icpx"
    "-DCUTLASS_ENABLE_SYCL=ON"
    "-DDPCPP_SYCL_TARGET=intel_gpu_pvc"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
    "-DCUTLASS_ENABLE_GTEST_UNIT_TESTS=OFF"
    "-DCUTLASS_ENABLE_TESTS=OFF"
    "-DCUTLASS_ENABLE_BENCHMARKS=OFF"
    "-DCUTLASS_ENABLE_HEADERS_ONLY=ON"
  ];

  installPhase = ''
        mkdir -p $out/lib $out/include $out/tools/util/include $out/lib/cmake/CutlassSycl
        cp -rn $src/include/* $out/include/
        cp -rn $src/tools/util/include/* $out/tools/util/include/
        cat > $out/lib/cmake/CutlassSycl/CutlassSyclConfig.cmake <<EOF
    set(CUTLASS_INCLUDE_DIR  "$out/include")
    set(CUTLASS_TOOLS_UTIL_INCLUDE_DIR "$out/tools/util/include")
    add_compile_definitions(CUTLASS_ENABLE_SYCL)
    add_compile_definitions(DPCPP_SYCL_TARGET=intel_gpu_pvc)
    add_compile_definitions(SYCL_INTEL_TARGET=1)
    set(ENV{SYCL_PROGRAM_COMPILE_OPTIONS} "-ze-opt-large-register-file")
    set(ENV{IGC_VISAOptions} "-perfmodel")
    set(ENV{IGC_VectorAliasBBThreshold} "10000")
    set(ENV{IGC_ExtraOCLOptions} "-cl-intel-256-GRF-per-thread")
    EOF
  '';
}
