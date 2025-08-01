final: prev:
rec {
  # Use MKL for BLAS/LAPACK on x86_64.
  blas = if final.stdenv.isx86_64 then prev.blas.override { blasProvider = prev.mkl; } else prev.blas;
  lapack =
    if final.stdenv.isx86_64 then prev.lapack.override { lapackProvider = prev.mkl; } else prev.blas;

  build2cmake = final.callPackage ./pkgs/build2cmake { };

  fetchKernel = final.callPackage ./pkgs/fetch-kernel { };

  # Used by ROCm.
  libffi_3_2 = final.libffi_3_3.overrideAttrs (
    finalAttrs: _: {
      version = "3.2.1";
      src = final.fetchurl {
        url = with finalAttrs; "https://gcc.gnu.org/pub/${pname}/${pname}-${version}.tar.gz";
        hash = "sha256-0G67jh2aItGeONY/24OVQlPzm+3F1GIyoFZFaFciyjc=";
      };
    }
  );

  magma-cuda-static = prev.magma-cuda-static.overrideAttrs (
    _: prevAttrs: { buildInputs = prevAttrs.buildInputs ++ [ (prev.lib.getLib prev.gfortran.cc) ]; }
  );

  magma-hip =
    (prev.callPackage ./pkgs/magma {
      cudaSupport = false;
      rocmSupport = true;
    }).magma;

  nvtx = final.callPackage ./pkgs/nvtx { };

  rocmPackages = final.rocmPackages_6_3;

  # Remove when we remove ROCm 6.2.
  suitesparse_4_4 = prev.suitesparse_4_4.overrideAttrs (
    _: prevAttrs: {
      postInstall =
        prevAttrs.postInstall
        + ''
          ln -s $out/lib/libsuitesparse.so $out/lib/libsuitesparse.so.4
          # All dynamic libraries are just symplinks to the main library.
          ln -s $out/lib/libsuitesparse.so $out/lib/libcholmod.so.3
          ln -s $out/lib/libsuitesparse.so $out/lib/libsuitesparseconfig.so.4
        '';
    }
  );

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (
      python-self: python-super: with python-self; {
        paged-attention = buildKernel rec {
          pname = "paged-attention";
          version = "0.0.3";
          src = fetchKernel {
            repo_id = "kernels-community/${pname}";
            inherit version;
            hash = "sha256-Nalnx3kjQcKOa5YaBSKRImnVUHq2lko1TMfFJ7ocTb4=";
          };
        };

        attention-kernels = callPackage ./pkgs/python-modules/attention-kernels { };

        awq-inference-engine = callPackage ./pkgs/python-modules/awq-inference-engine { };

        buildKernel = callPackage ./pkgs/python-modules/build-kernel { };

        causal-conv1d = callPackage ./pkgs/python-modules/causal-conv1d { };

        compressed-tensors = callPackage ./pkgs/python-modules/compressed-tensors { };

        einops = python-super.einops.overrideAttrs (
          _: prevAttrs: {
            disabledTests = prevAttrs.disabledTests ++ [
              # Times out...
              "test_notebook_3"
            ];
          }
        );

        exllamav2 = callPackage ./pkgs/python-modules/exllamav2 { };

        flash-attn = callPackage ./pkgs/python-modules/flash-attn { };

        flash-attn-layer-norm = callPackage ./pkgs/python-modules/flash-attn-layer-norm { };

        flash-attn-rotary = callPackage ./pkgs/python-modules/flash-attn-rotary { };

        flash-attn-v1 = callPackage ./pkgs/python-modules/flash-attn-v1 { };

        flashinfer = callPackage ./pkgs/python-modules/flashinfer { };

        hf-transfer = callPackage ./pkgs/python-modules/hf-transfer { };

        hf-xet = callPackage ./pkgs/python-modules/hf-xet { };

        kernels = callPackage ./pkgs/python-modules/kernels { };

        marlin-kernels = callPackage ./pkgs/python-modules/marlin-kernels { };

        mktestdocs = callPackage ./pkgs/python-modules/mktestdocs { };

        moe = buildKernel rec {
          pname = "moe";
          version = "0.3.0";
          src = fetchKernel {
            repo_id = "kernels-community/${pname}";
            inherit version;
            hash = "sha256-CR0fgiooxt+pBE/VQETjNn7i0jSCD0g2NDC7KdNNIrc=";
          };
        };

        moe-kernels = callPackage ./pkgs/python-modules/moe-kernels { };

        #opentelemetry-proto = python-super.opentelemetry-proto.override { protobuf = super.protobuf3_24; };

        opentelemetry-instrumentation-grpc = python-super.opentelemetry-instrumentation-grpc.overrideAttrs (
          _: prevAttrs: {
            patches = [ ];

            # Overwrite old protobuf files which leads to failing.
            preCheck = ''
              python -m grpc_tools.protoc -Itests/protobuf --python_out=tests/protobuf \
               --grpc_python_out=tests/protobuf tests/protobuf/test_server.proto # --mypy_out=text_generation_server/pb 
            '';

            nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ python-super.grpcio-tools ];
          }
        );

        mamba-ssm = callPackage ./pkgs/python-modules/mamba-ssm { };

        punica-sgmv = buildKernel rec {
          pname = "punica-sgmv";
          version = "0.0.1";
          src = fetchKernel {
            repo_id = "kernels-community/${pname}";
            #inherit version;
            rev = "5a84343633e93e2866f4e907dfc26b1ee07467ae";
            hash = "sha256-z2em4jEZSgDfPX6s4jykVpuJOI1LRbI69Xq1T5lTM7s=";
          };
          cutlass = final.cutlass_3_6;
        };

        quantization = buildKernel rec {
          pname = "quantization";
          version = "0.0.4";
          src = fetchKernel {
            repo_id = "kernels-community/${pname}";
            inherit version;
            hash = "sha256-qAMKM+2pKbYkJ9bHWlVijKcknrBjeFHLTXU2LCKA2dw=";
          };
          cutlass = final.cutlass_3_6;
        };

        quantization-eetq = buildKernel rec {
          pname = "quantization-eetq";
          version = "0.0.2";
          src = fetchKernel {
            repo_id = "kernels-community/${pname}";
            inherit version;
            hash = "sha256-TiJAGEpZAR/UxovzsVhc5mto3FD4LA8urE04XA2D4KQ=";
          };
          cutlass = final.cutlass_2_10;
        };

        rotary = buildKernel rec {
          pname = "rotary";
          version = "0.0.2";
          src = fetchKernel {
            repo_id = "kernels-community/${pname}";
            inherit version;
            hash = "sha256-D5/ErUNCQbNrbLGBNiucuWocyv+343W7tius6NcM9iQ=";
          };
        };

        scipy = python-super.scipy.overrideAttrs (
          _: prevAttrs: {
            # Three tests have a slight deviance.
            doCheck = false;
            doInstallCheck = false;
          }
        );

        torch = python-self.torch_2_7;

        torch_2_6 = callPackage ./pkgs/python-modules/torch_2_6 { };

        torch_2_7 = callPackage ./pkgs/python-modules/torch_2_7 { };

        torch_2_8 = callPackage ./pkgs/python-modules/torch_2_8 { };

        triton-rocm = callPackage ./pkgs/python-modules/triton-rocm { };
      }
    )
  ];
}
// (import ./pkgs/cutlass { pkgs = final; })
// (
  let
    flattenVersion = prev.lib.strings.replaceStrings [ "." ] [ "_" ];
    readPackageMetadata = path: (builtins.fromJSON (builtins.readFile path));
    versions = [
      "6.2.4"
      "6.3.4"
      "6.4.2"
    ];
    newRocmPackages = final.callPackage ./pkgs/rocm-packages { };
  in
  builtins.listToAttrs (
    map (version: {
      name = "rocmPackages_${flattenVersion (prev.lib.versions.majorMinor version)}";
      value = newRocmPackages {
        packageMetadata = readPackageMetadata ./pkgs/rocm-packages/rocm-${version}-metadata.json;
      };
    }) versions
  )
)
