{
  description = "Hugging Face Nix overlay";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    {
      self,
      flake-compat,
      flake-utils,
      nixpkgs,
    }:
    let
      isCudaSystem = system: system == "x86_64-linux" || system == "aarch64-linux";
      cudaConfig = {
        allowUnfree = true;
        cudaSupport = true;
        cudaCapabilities = [
          "7.5"
          "8.0"
          "8.6"
          "8.9"
          "9.0"
          "9.0a"
        ];
      };

      rocmConfig = {
        allowUnfree = true;
        rocmSupport = true;
      };

      xpuConfig = {
        allowUnfree = true;
        xpuSupport = true;
      };

      overlay = import ./overlay.nix;
    in
    flake-utils.lib.eachSystem
      (with flake-utils.lib.system; [
        aarch64-darwin
        x86_64-linux
      ])
      (
        system:
        let
          pkgsCuda = import nixpkgs {
            inherit system;
            config = cudaConfig;
            overlays = [ overlay ];
          };
          pkgsRocm = import nixpkgs {
            inherit system;
            config = rocmConfig;
            overlays = [ overlay ];
          };
          pkgsXpu = import nixpkgs {
            inherit system;
            config = xpuConfig;
            overlays = [ overlay ];
          };
          pkgsGeneric = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
          pkgs = if isCudaSystem system then pkgsCuda else pkgsGeneric;
          inherit (pkgs) lib;
        in
        rec {
          formatter = pkgs.nixfmt-tree;
          packages = rec {
            all =
              let
                filterDist = lib.filter (output: output != "dist");
              in
              pkgs.symlinkJoin {
                name = "all";
                paths =
                  # Ensure that we build all Torch outputs for caching.
                  builtins.map (output: python3Packages.torch.${output}) (filterDist python3Packages.torch.outputs)
                  ++ builtins.filter (lib.meta.availableOn { inherit system; }) (lib.attrValues python3Packages);
              };
            lib = pkgs.lib;
            python3Packages = with pkgs.python3.pkgs; {
              inherit

                awq-inference-engine
                causal-conv1d
                compressed-tensors
                exllamav2
                flash-attn
                flash-attn-layer-norm
                flash-attn-rotary
                flash-attn-v1
                flashinfer
                hf-transfer
                hf-xet
                huggingface-hub
                kernels
                mamba-ssm
                mktestdocs
                moe
                opentelemetry-instrumentation-grpc
                paged-attention
                punica-sgmv
                quantization
                quantization-eetq
                rotary
                torch
                transformers
                ;
            };

            xpu = {
              python3Packages = with pkgsXpu.python3.pkgs; {
                inherit torch torch_2_7 torch_2_8;
              };
            };

            rocm = {
              python3Packages = with pkgsRocm.python3.pkgs; {
                inherit torch;
              };
            };
          };
        }
      )
    // {

      # Cheating a bit to conform to the schema.
      lib.config = system: if isCudaSystem system then cudaConfig else { };
      overlays.default = overlay;
    };
}
