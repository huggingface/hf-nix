{
  lib,
  config,
  replaceVars,
  runCommand,
  addDriverRunpath,
  cudaPackages,
  cudaSupport ? config.cudaSupport,
  python,
  rocmPackages,
  triton-no-cuda,
  triton-llvm,
}:
let
  # Override to cherry-pick changes from:
  #
  # https://github.com/NixOS/nixpkgs/pull/436500
  #
  # Not needed anymore once this is merged and nixpkgs bumped.
  triton =
    (triton-no-cuda.override (_old: {
      inherit rocmPackages;
      rocmSupport = true;
    })).overridePythonAttrs
      (old: {
        doCheck = false;
        buildInputs = old.buildInputs ++ [
          rocmPackages.clr
        ];
        dontStrip = true;
        env = old.env // {
          CXXFLAGS = "-O3 -I${rocmPackages.clr}/include -I/build/source/third_party/triton/third_party/nvidia/backend/include";
          TRITON_OFFLINE_BUILD = 1;
        };
        patches = [
          (replaceVars ./0001-_build-allow-extra-cc-flags.patch {
            ccCmdExtraFlags = "-Wl,-rpath,${addDriverRunpath.driverLink}/lib";
          })
          (replaceVars ./0002-nvidia-driver-short-circuit-before-ldconfig.patch {
            libcudaStubsDir =
              if cudaSupport then "${lib.getOutput "stubs" cudaPackages.cuda_cudart}/lib/stubs" else null;
          })
          # Upstream PR: https://github.com/triton-lang/triton/pull/7959
          ./0005-amd-search-env-paths.patch
        ]
        ++ lib.optionals cudaSupport [
          (replaceVars ./0003-nvidia-cudart-a-systempath.patch {
            cudaToolkitIncludeDirs = "${lib.getInclude cudaPackages.cuda_cudart}/include";
          })
          (replaceVars ./0004-nvidia-allow-static-ptxas-path.patch {
            nixpkgsExtraBinaryPaths = lib.escapeShellArgs [ (lib.getExe' cudaPackages.cuda_nvcc "ptxas") ];
          })
        ];
        postPatch =
          old.postPatch
          # Don't use FHS path for ROCm LLD
          # Remove this after `[AMD] Use lld library API #7548` makes it into a release
          + ''
            substituteInPlace third_party/amd/backend/compiler.py \
              --replace-fail 'lld = Path("/opt/rocm/llvm/bin/ld.lld")' \
              "import os;lld = Path(os.getenv('HIP_PATH', '/opt/rocm/')"' + "/llvm/bin/ld.lld")'
          '';

        passthru.tests = old.passthru.tests // {
          # Test that _get_path_to_hip_runtime_dylib works when ROCm is available at runtime
          rocm-libamdhip64-path =
            runCommand "triton-rocm-libamdhip64-path-test"
              {
                buildInputs = [
                  triton
                  python
                  rocmPackages.clr
                ];
              }
              ''
                python -c "
                import os
                import triton
                path = triton.backends.amd.driver._get_path_to_hip_runtime_dylib()
                print(f'libamdhip64 path: {path}')
                assert os.path.exists(path)
                " && touch $out
              '';

          # Test that path_to_rocm_lld works when ROCm is available at runtime
          # Remove this after `[AMD] Use lld library API #7548` makes it into a release
          rocm-lld-path =
            runCommand "triton-rocm-lld-test"
              {
                buildInputs = [
                  triton
                  python
                  rocmPackages.clr
                ];
              }
              ''
                python -c "
                import os
                import triton
                path = triton.backends.backends['amd'].compiler.path_to_rocm_lld()
                print(f'ROCm LLD path: {path}')
                assert os.path.exists(path)
                " && touch $out
              '';
        };
      });
in
triton
