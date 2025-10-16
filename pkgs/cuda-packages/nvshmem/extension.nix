{
  cudaMajorVersion,
  lib,
  stdenv,
}:
let
  cudaVersionToHash = {
    "12" = {
      x86_64-linux = {
        version = "3.4.5";
        hash = "sha256-BYy63cT/hka40b2TIuk8kOrlTIbhrIki8g2KVaf6i34=";
      };
      aarch64-linux = {
        version = "3.4.5";
        hash = "sha256-IcHv5nd9v8u8kkRLQgqrOZ9bVZAoTOCfHM2Ow1FrGSw=";
      };
    };
    "13" = {
      x86_64-linux = {
        version = "3.4.5";
        hash = "sha256-GPEoB8I7xbJwWBrx+br9VANp2ng+VXFxVYiHYj13hCw=";
      };
      aarch64-linux = {
        version = "3.4.5";
        hash = "sha256-CA4spt9GOl8/X1Cjkj711JFQODc0NkmpIssXcYaJ/AY=";
      };
    };
  };

  inherit (stdenv.hostPlatform) system;

  # nvshmem is only available for new CUDA versions.
  cudaVersionIsSupported = cudaVersionToHash ? ${cudaMajorVersion};
  platformIsSupported = cudaVersionIsSupported && cudaVersionToHash.${cudaMajorVersion} ? ${system};
  isSupported = cudaVersionIsSupported && platformIsSupported;

  # Build our extension
  extension =
    final: _:
    lib.attrsets.optionalAttrs isSupported {
      nvshmem = final.callPackage ./generic.nix {
        inherit (cudaVersionToHash.${cudaMajorVersion}.${system}) hash version;
      };
    };
in
extension
