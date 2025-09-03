{
  stdenv
, buildPythonPackage
, setuptools
, distutils
, wheel
, fetchFromGitHub
, triton-llvm
, xpuPackages
, torchVersion ? "2.7"
, cmake
, ninja
, lib
, python
, pybind11
, pkg-config
, pkgs
, autoPatchelfHook
}:

let
  llvm_rev =
    if torchVersion == "2.7" then "1188b1ff7b956cb65d8ddda5f1e56c432f1a57c7"
    else if torchVersion == "2.8" then "e12cbd8339b89563059c2bb2a312579b652560d0"
    else "1188b1ff7b956cb65d8ddda5f1e56c432f1a57c7";
  llvm_hash =
    if torchVersion == "2.7" then "sha256-iwG0bWnrVX9xbHB4eIe/JxQNFdDHb/COXo4d0joOlDE="
    else if torchVersion == "2.8" then "sha256-BtMEDk7P7P5k+s2Eb1Ej2QFvjl0A8gN7Tq/Kiu+Pqe4="
    else "sha256-iwG0bWnrVX9xbHB4eIe/JxQNFdDHb/COXo4d0joOlDE=";

  llvm = triton-llvm.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "llvm";
      repo = "llvm-project";
      rev = llvm_rev;
      hash = llvm_hash;
    };
    pname = "triton-llvm-xpu";
    outputs = [ "out" ];
    cmakeFlags = [
      "-G" "Ninja"
      "-DCMAKE_BUILD_TYPE=Release"
      "-DLLVM_ENABLE_ASSERTIONS=ON"
      "-DLLVM_ENABLE_PROJECTS=mlir;llvm"
      "-DLLVM_TARGETS_TO_BUILD=X86;NVPTX;AMDGPU;SPIRV"
      "-DLLVM_INSTALL_UTILS=true"
      "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
    ];
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ autoPatchelfHook ];
  });

  triton_rev =
    if torchVersion == "2.7" then "0bcc8265e677e5321606a3311bf71470f14456a8"
    else if torchVersion == "2.8" then "ae324eeac8e102a2b40370e341460f3791353398"
    else "0bcc8265e677e5321606a3311bf71470f14456a8";
  triton_hash =
    if torchVersion == "2.7" then "sha256-R5UbAVIjIBFuBB9Nf638MloZWddTk/sqFNFhqtuD/DI="
    else if torchVersion == "2.8" then "sha256-rHy/gIH3pYYlmSd6OuRJdB3mJvzeVI2Iav9rszCeV8I="
    else "sha256-R5UbAVIjIBFuBB9Nf638MloZWddTk/sqFNFhqtuD/DI=";
  spirv_llvm_rev =
    if torchVersion == "2.7"then "4eea290c449fca2efd28cfa46d3946c5feaf988c"
    else if torchVersion == "2.8" then "96f5ade29c9088ea89533a7e3ca70a9f9464f343"
    else "4eea290c449fca2efd28cfa46d3946c5feaf988c";
  spirv_llvm_hash =
    if torchVersion == "2.7" then "sha256-IBPlhtkFxghvq1FGRqQJYtA3P6vZmpkDANZaAhnLtKc="
    else if torchVersion == "2.8" then "sha256-phbljvV08uWhFJie7XrodLIc97vU4o7zAI1zonN4krY="
    else "sha256-IBPlhtkFxghvq1FGRqQJYtA3P6vZmpkDANZaAhnLtKc=";
  spirv_head_rev =
    if torchVersion == "2.7" then "2b2e05e088841c63c0b6fd4c9fb380d8688738d3"
    else if torchVersion == "2.8" then "c9aad99f9276817f18f72a4696239237c83cb775"
    else "2b2e05e088841c63c0b6fd4c9fb380d8688738d3";
  spirv_head_hash =
    if torchVersion == "2.7" then "sha256-EZrWquud9CFrDNdskObCQQCR0HsXOZmJohh/0ybaT7g="
    else if torchVersion == "2.8" then "sha256-/KfUxWDczLQ/0DOiFC4Z66o+gtoF/7vgvAvKyv9Z9OA="
    else "sha256-EZrWquud9CFrDNdskObCQQCR0HsXOZmJohh/0ybaT7g=";

  buildPhaseStr =
    if torchVersion == "2.7" then ''
      cd python
      ${python.pythonOnBuildForHost.interpreter} setup.py bdist_wheel
    ''
    else if torchVersion == "2.8" then ''
      ${python.pythonOnBuildForHost.interpreter} setup.py bdist_wheel
    ''
    else ''
      cd python
      ${python.pythonOnBuildForHost.interpreter} setup.py bdist_wheel
    '';

in

buildPythonPackage rec {
  pname = "triton-xpu";
  version = torchVersion;
  format = "other";
  dontUseCmakeConfigure = true;

  src = fetchFromGitHub {
    owner = "intel";
    repo = "intel-xpu-backend-for-triton";
    rev = triton_rev;
    hash = triton_hash;
  };

  spirvLlvmTranslatorSrc = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-LLVM-Translator";
    rev = spirv_llvm_rev;
    hash = spirv_llvm_hash;
  };

  spirvHeadersSrc = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
    rev = spirv_head_rev;
    hash = spirv_head_hash;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    pkgs.python3Packages.lit
    pkgs.python3Packages.pip
  ];

  buildInputs = [
    llvm
    xpuPackages.oneapi-torch-dev
    setuptools
    distutils
    pybind11
    wheel
    pkgs.libxml2.dev
  ];

  dontStrip = true;

  buildPhase = buildPhaseStr;

  installPhase = ''
    WHEEL=$(find $PWD -name "*.whl" | head -n1)
    echo "Found wheel: $WHEEL"
    ${python.pythonOnBuildForHost.interpreter} -m pip install --no-deps --prefix=$out "$WHEEL"
  '';

  pythonImportsCheck = [
    "triton"
    "triton.language"
  ];

  postPatch = ''
  sed -i '/if (NOT SPIRVToLLVMTranslator_FOUND)/,/endif (NOT SPIRVToLLVMTranslator_FOUND)/c\
set(SPIRVToLLVMTranslator_SOURCE_DIR "${spirvLlvmTranslatorSrc}")\n\
set(SPIRVToLLVMTranslator_BINARY_DIR \''${CMAKE_CURRENT_BINARY_DIR}/SPIRVToLLVMTranslator-build)\n\
set(LLVM_CONFIG \''${LLVM_LIBRARY_DIR}/../bin/llvm-config)\n\
set(LLVM_DIR \''${LLVM_LIBRARY_DIR}/cmake/llvm CACHE PATH "Path to LLVM build dir " FORCE)\n\
set(LLVM_SPIRV_BUILD_EXTERNAL YES CACHE BOOL "Build SPIRV-LLVM Translator as external" FORCE)\n\
set(LLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR ${spirvHeadersSrc})\n\
add_subdirectory(\''${SPIRVToLLVMTranslator_SOURCE_DIR} \''${CMAKE_CURRENT_BINARY_DIR}/SPIRVToLLVMTranslator-build)\n\
set(SPIRVToLLVMTranslator_INCLUDE_DIR \''${SPIRVToLLVMTranslator_SOURCE_DIR}/include CACHE INTERNAL "SPIRVToLLVMTranslator_INCLUDE_DIR")\n\
find_package_handle_standard_args(\n\
        SPIRVToLLVMTranslator\n\
        FOUND_VAR SPIRVToLLVMTranslator_FOUND\n\
        REQUIRED_VARS\n\
            SPIRVToLLVMTranslator_SOURCE_DIR)\n\
' third_party/intel/cmake/FindSPIRVToLLVMTranslator.cmake
'';

  # Set LLVM env vars for build
  env = {
    LLVM_INCLUDE_DIRS = "${llvm}/include";
    LLVM_LIBRARY_DIR = "${llvm}/lib";
    LLVM_SYSPATH = "${llvm}";
    TRITON_OFFLINE_BUILD = 1;
    TRITON_BUILD_PROTON = 0;
  };
}
