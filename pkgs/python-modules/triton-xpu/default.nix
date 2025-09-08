{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  cmake,
  pkg-config,
  ninja,
  setuptools,
  wheel,
  distutils,
  libxml2,
  pybind11,
  python,
  triton-llvm,
  xpuPackages,

  torchVersion ? "2.7",
}:

let
  torchTritonVersions = {
    "2.7" = {
      llvm = {
        rev = "1188b1ff7b956cb65d8ddda5f1e56c432f1a57c7";
        hash = "sha256-iwG0bWnrVX9xbHB4eIe/JxQNFdDHb/COXo4d0joOlDE=";
      };
      triton = {
        rev = "0bcc8265e677e5321606a3311bf71470f14456a8";
        hash = "sha256-R5UbAVIjIBFuBB9Nf638MloZWddTk/sqFNFhqtuD/DI=";
      };
      spirv_llm = {
        rev = "4eea290c449fca2efd28cfa46d3946c5feaf988c";
        hash = "sha256-IBPlhtkFxghvq1FGRqQJYtA3P6vZmpkDANZaAhnLtKc=";
      };
      spirv_headers = {
        rev = "2b2e05e088841c63c0b6fd4c9fb380d8688738d3";
        hash = "sha256-EZrWquud9CFrDNdskObCQQCR0HsXOZmJohh/0ybaT7g=";
      };
    };
    "2.8" = {
      llvm = {
        rev = "e12cbd8339b89563059c2bb2a312579b652560d0";
        hash = "sha256-BtMEDk7P7P5k+s2Eb1Ej2QFvjl0A8gN7Tq/Kiu+Pqe4=";
      };
      triton = {
        rev = "ae324eeac8e102a2b40370e341460f3791353398";
        hash = "sha256-rHy/gIH3pYYlmSd6OuRJdB3mJvzeVI2Iav9rszCeV8I=";
      };
      spirv_llm = {
        rev = "96f5ade29c9088ea89533a7e3ca70a9f9464f343";
        hash = "sha256-phbljvV08uWhFJie7XrodLIc97vU4o7zAI1zonN4krY=";
      };
      spirv_headers = {
        rev = "c9aad99f9276817f18f72a4696239237c83cb775";
        hash = "sha256-/KfUxWDczLQ/0DOiFC4Z66o+gtoF/7vgvAvKyv9Z9OA=";
      };
    };
  };
  tritonVersions =
    torchTritonVersions.${torchVersion} or (throw "Unsupported Torch version: ${torchVersion}");

  llvmBase = triton-llvm.override {
    llvmTargetsToBuild = [
      "X86"
      "SPIRV"
    ];
  };
  llvm = llvmBase.overrideAttrs (old: {
    src = fetchFromGitHub {
      inherit (tritonVersions.llvm) rev hash;
      owner = "llvm";
      repo = "llvm-project";
    };
    pname = "triton-llvm-xpu";
    outputs = [ "out" ];
  });

  spirvLlvmTranslatorSrc = fetchFromGitHub {
    inherit (tritonVersions.spirv_llm) rev hash;
    owner = "KhronosGroup";
    repo = "SPIRV-LLVM-Translator";
  };

  spirvHeadersSrc = fetchFromGitHub {
    inherit (tritonVersions.spirv_headers) rev hash;
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
  };

in

buildPythonPackage rec {
  pname = "triton-xpu";
  version = torchVersion;
  pyproject = true;
  dontUseCmakeConfigure = true;

  src = fetchFromGitHub {
    inherit (tritonVersions.triton) rev hash;
    owner = "intel";
    repo = "intel-xpu-backend-for-triton";
  };

  sourceRoot = if torchVersion == "2.7" then "${src.name}/python" else "${src.name}";

  postPatch = ''
    chmod -R u+w $NIX_BUILD_TOP/source
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
      ' $NIX_BUILD_TOP/source/third_party/intel/cmake/FindSPIRVToLLVMTranslator.cmake
  '';

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  build-system = with python.pkgs; [
    lit
    pip
    setuptools
  ];

  buildInputs = [
    llvm
    xpuPackages.oneapi-torch-dev
    pybind11
    libxml2.dev
  ];

  depends = [
    setuptools
    distutils
    wheel
  ];

  # Needd to avoid creating symlink: /homeless-shelter [...]
  preBuild = ''
    export HOME=$(mktemp -d)
  '';

  pythonImportsCheck = [
    "triton"
    "triton.language"
  ];

  # Set LLVM env vars for build
  env = {
    LLVM_INCLUDE_DIRS = "${llvm}/include";
    LLVM_LIBRARY_DIR = "${llvm}/lib";
    LLVM_SYSPATH = "${llvm}";
    TRITON_OFFLINE_BUILD = 1;
    TRITON_BUILD_PROTON = 0;
  };
}
