{
  lib,
  autoAddDriverRunpath,
  autoPatchelfHook,
  backendStdenv,
  cudaMajorVersion,
  fetchurl,
  stdenv,

  libfabric,
  openmpi,
  rdma-core,
  ucx,

  hash,
  version,
}:
let
  inherit (lib) lists strings;
  cudaArch =
    if backendStdenv.hostPlatform.isx86_64 then
      "x86_64"
    else if backendStdenv.hostPlatform.isAarch64 then
      "sbsa"
    else
      throw "Unsupported platform";
in
backendStdenv.mkDerivation (finalAttrs: {
  strictDeps = true;

  pname = "nvshmem";
  inherit version;

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://developer.download.nvidia.com/compute/nvshmem/redist/libnvshmem/linux-${cudaArch}/lib${finalAttrs.pname}-linux-${cudaArch}-${version}_cuda${cudaMajorVersion}-archive.tar.xz";
    inherit hash;
  };

  nativeBuildInputs = [
    autoAddDriverRunpath
    autoPatchelfHook
  ];

  buildInputs = [
    libfabric
    openmpi
    rdma-core
    stdenv.cc.cc
    ucx
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r lib $out/

    mkdir -p $dev
    cp -r include $dev/

    runHook postInstall
  '';
})
