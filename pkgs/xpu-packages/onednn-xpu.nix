{
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  gcc,
  writeShellScriptBin,
  setupXpuHook,
  oneapi-torch-dev,
  dpcppVersion,
}:

let
  version =
    if dpcppVersion == "2025.1" then
      "3.8.1"
    else if dpcppVersion == "2025.0" then
      "3.7.1"
    else
      "3.8.1";
  rev =
    if dpcppVersion == "2025.1" then
      "v3.8.1"
    else if dpcppVersion == "2025.0" then
      "v3.7.1"
    else
      "v3.8.1";
  sha256 =
    if dpcppVersion == "2025.1" then
      "sha256-x4leRd0xPFUygjAv/D125CIXn7lYSyzUKsd9IDh/vCc="
    else if dpcppVersion == "2025.0" then
      "sha256-+4z5l0mJsw0SOW245GfZh41mdHGZ8u+xED7afm6pQjs="
    else
      "sha256-x4leRd0xPFUygjAv/D125CIXn7lYSyzUKsd9IDh/vCc=";
in
stdenv.mkDerivation rec {
  pname = "onednn-xpu";
  inherit version;

  src = fetchFromGitHub {
    owner = "oneapi-src";
    repo = "oneDNN";
    inherit rev sha256;
  };

  env.CXXFLAGS = "-isystem${oneapi-torch-dev}/oneapi/compiler/latest/lib/clang/21/include -I${stdenv.cc.libc_dev}/include -I${gcc.cc}/include/c++/${gcc.version}  -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu";
  env.LDFLAGS =
    "-L${stdenv.cc}/lib -L${stdenv.cc}/lib64"
    + " -L${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version}"
    + " -L${stdenv.cc.cc.lib}/lib";

  nativeBuildInputs = [
    (writeShellScriptBin "icx" ''
      exec ${oneapi-torch-dev}/oneapi/compiler/latest/bin/icx \
      -B${stdenv.cc.libc}/lib -B${oneapi-torch-dev}/oneapi/compiler/latest/lib/crt -isysroot ${stdenv.cc.libc_dev} -isystem${stdenv.cc.libc_dev}/include \
      "$@"
    '')
    (writeShellScriptBin "icpx" ''
      exec  ${oneapi-torch-dev}/oneapi/compiler/latest/bin/icpx \
      -B${stdenv.cc.libc}/lib -B${oneapi-torch-dev}/oneapi/compiler/latest/lib/crt -isysroot ${stdenv.cc.libc_dev} -isystem${stdenv.cc.libc_dev}/include \
      "$@"
    '')
    (writeShellScriptBin "g++" ''
      exec ${gcc.cc}/bin/g++ \
        -nostdinc  \
        -isysroot ${stdenv.cc.libc_dev} \
        -isystem${stdenv.cc.libc_dev}/include \
        -I${gcc.cc}/include/c++/${gcc.version} \
        -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu \
        -I${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version}/include \
        "$@"
    '')
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
    "-DDNNL_DPCPP_HOST_COMPILER=g++"
    "-DOpenCL_LIBRARY=${oneapi-torch-dev}/oneapi/compiler/latest/lib/libOpenCL.so"
    "-DOpenCL_INCLUDE_DIR=${oneapi-torch-dev}/oneapi/compiler/latest/include"
  ];

  installPhase = ''
    mkdir -p $out/lib $out/include
    find . -name '*.a' -exec cp {} $out/lib/ \;
    cp -rn $src/include/* $out/include/
    chmod +w $out/include/oneapi/dnnl
    cp -rn include/oneapi/dnnl/* $out/include/oneapi/dnnl/
    if [ "$version" = "3.8.1" ]; then
      cp -rn "$src/third_party/level_zero" "$out/include/"
    else
      cp -rn "$src/src/gpu/intel/sycl/l0/level_zero" "$out/include/"
    fi
  '';
}
