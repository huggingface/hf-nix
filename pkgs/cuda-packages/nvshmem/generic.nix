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
    url = "https://developer.download.nvidia.com/compute/nvshmem/redist/libnvshmem/linux-x86_64/lib${finalAttrs.pname}-linux-x86_64-${version}_cuda${cudaMajorVersion}-archive.tar.xz";
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
