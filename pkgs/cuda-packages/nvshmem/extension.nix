{
  cudaMajorVersion,
  lib,
  stdenv,
}:
let
  cudaVersionToHash = {
    "12" = {
      version = "3.4.5";
      hash = "sha256-BYy63cT/hka40b2TIuk8kOrlTIbhrIki8g2KVaf6i34=";
    };
    "13" = {
      version = "3.4.5";
      hash = "sha256-GPEoB8I7xbJwWBrx+br9VANp2ng+VXFxVYiHYj13hCw=";
    };
  };

  inherit (stdenv) hostPlatform;

  # nvshmem is only available for new CUDA versions.
  cudaVersionIsSupported = cudaVersionToHash ? ${cudaMajorVersion};
  platformIsSupported = hostPlatform.isx86_64;
  isSupported = cudaVersionIsSupported && platformIsSupported;

  # Build our extension
  extension =
    final: _:
    lib.attrsets.optionalAttrs isSupported {
      nvshmem = final.callPackage ./generic.nix {
        inherit (cudaVersionToHash.${cudaMajorVersion}) hash version;
      };
    };
in
extension
