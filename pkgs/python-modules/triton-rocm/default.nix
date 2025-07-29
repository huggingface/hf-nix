{
  triton-no-cuda,
  rocmPackages,
  fetchFromGitHub,
  triton-llvm,
}:
let
  llvm = triton-llvm.overrideAttrs {
    src = fetchFromGitHub {
      owner = "llvm";
      repo = "llvm-project";
      # make sure this matches triton llvm rel branch hash for now
      # https://github.com/triton-lang/triton/blob/release/3.2.x/cmake/llvm-hash.txt
      rev = "86b69c31642e98f8357df62c09d118ad1da4e16a";
      hash = "sha256-W/mQwaLGx6/rIBjdzUTIbWrvGjdh7m4s15f70fQ1/hE=";
    };
    pname = "triton-llvm-rocm";
    patches = [ ]; # FIXME: https://github.com/llvm/llvm-project//commit/84837e3cc1cf17ed71580e3ea38299ed2bfaa5f6.patch doesn't apply, may need to rebase
  };
in
(triton-no-cuda.override (_old: {
  inherit llvm rocmPackages;
  rocmSupport = true;
})).overridePythonAttrs
  (old: {
    doCheck = false;
    version = "3.2.0";
    src = fetchFromGitHub {
      owner = "triton-lang";
      repo = "triton";
      rev = "9641643da6c52000c807b5eeed05edaec4402a67"; # "release/3.2.x";
      hash = "sha256-V1lpARwOLn28ZHfjiWR/JJWGw3MB34c+gz6Tq1GOVfo=";
    };
    buildInputs = old.buildInputs ++ [
      rocmPackages.clr
    ];
    dontStrip = true;
    env = old.env // {
      CXXFLAGS = "-O3 -I${rocmPackages.clr}/include -I/build/source/third_party/triton/third_party/nvidia/backend/include";
      TRITON_OFFLINE_BUILD = 1;
    };
    patches = [ ];
    postPatch = ''
      # Remove nvidia backend so we don't depend on unfree nvidia headers
      # when we only want to target ROCm
      rm -rf third_party/nvidia
      substituteInPlace CMakeLists.txt \
        --replace-fail "add_subdirectory(test)" ""
      sed -i '/nvidia\|NVGPU\|registerConvertTritonGPUToLLVMPass\|mlir::test::/Id' bin/RegisterTritonDialects.h
      sed -i '/TritonTestAnalysis/Id' bin/CMakeLists.txt
      substituteInPlace python/setup.py \
        --replace-fail 'backends = [*BackendInstaller.copy(["nvidia", "amd"]), *BackendInstaller.copy_externals()]' \
        'backends = [*BackendInstaller.copy(["amd"]), *BackendInstaller.copy_externals()]'
      find . -type f -exec sed -i 's|[<]cupti.h[>]|"cupti.h"|g' {} +
      find . -type f -exec sed -i 's|[<]cuda.h[>]|"cuda.h"|g' {} +
      # remove any downloads
      substituteInPlace python/setup.py \
        --replace-fail "[get_json_package_info()]" "[]"\
        --replace-fail "[get_llvm_package_info()]" "[]"\
        --replace-fail "curr_version != version" "False"
      # Don't fetch googletest
      substituteInPlace cmake/AddTritonUnitTest.cmake \
        --replace-fail 'include(''${PROJECT_SOURCE_DIR}/unittest/googletest.cmake)' "" \
        --replace-fail "include(GoogleTest)" "find_package(GTest REQUIRED)"
      substituteInPlace third_party/amd/backend/compiler.py \
        --replace-fail '"/opt/rocm/llvm/bin/ld.lld"' "os.environ['ROCM_PATH']"' + "/llvm/bin/ld.lld"'
    '';
  })
