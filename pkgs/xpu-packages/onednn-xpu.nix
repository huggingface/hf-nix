{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  gcc,
  setupXpuHook,
  oneapi-torch-dev,
  intel-oneapi-dpcpp-cpp,
}:

let
  dpcppVersion = intel-oneapi-dpcpp-cpp.version;
  oneDnnVersions = {
    "2025.0" = {
      version = "3.7.1";
      hash = "sha256-+4z5l0mJsw0SOW245GfZh41mdHGZ8u+xED7afm6pQjs=";
    };
    "2025.1" = {
      version = "3.8.1";
      hash = "sha256-x4leRd0xPFUygjAv/D125CIXn7lYSyzUKsd9IDh/vCc=";
    };
  };
  oneDnnVersion =
    oneDnnVersions.${lib.versions.majorMinor dpcppVersion}
    or (throw "Unsupported DPC++ version: ${dpcppVersion}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "onednn-xpu";
  inherit (oneDnnVersion) version;

  src = fetchFromGitHub {
    owner = "oneapi-src";
    repo = "oneDNN";
    tag = "v${oneDnnVersion.version}";
    inherit (oneDnnVersion) hash;
  };

  nativeBuildInputs = [
    cmake
    ninja
    setupXpuHook
    oneapi-torch-dev
  ];

  cmakeFlags = [
    "-DCMAKE_C_COMPILER=icx"
    "-DCMAKE_CXX_COMPILER=icpx"
    "-DDNNL_GPU_RUNTIME=SYCL"
    "-DDNNL_CPU_RUNTIME=THREADPOOL"
    "-DDNNL_BUILD_TESTS=OFF"
    "-DDNNL_BUILD_EXAMPLES=OFF"
    "-DONEDNN_BUILD_GRAPH=ON"
    "-DDNNL_LIBRARY_TYPE=STATIC"
  ];

  postInstall = ''
    if [ "${finalAttrs.version}" = "3.8.1" ]; then
      cp -rn "$src/third_party/level_zero" "$out/include/"
    else
      cp -rn "$src/src/gpu/intel/sycl/l0/level_zero" "$out/include/"
    fi
  '';
})
