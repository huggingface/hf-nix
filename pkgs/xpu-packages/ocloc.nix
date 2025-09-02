{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  ocloc,
  zlib,
  zstd,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ocloc";
  version = "25.27";

  srcs = [
    (fetchurl {
      url = "https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/intel-ocloc_25.27.34303.5-0_amd64.deb";
      hash = "sha256-SfiMfWqYXvlFRCYXVbAdxtuhaeTFNOBr/nfxhsBod0w=";
    })
    (fetchurl {
      url = "https://github.com/intel/intel-graphics-compiler/releases/download/v2.14.1/intel-igc-core-2_2.14.1+19448_amd64.deb";
      hash = "sha256-ihDSRsCDo0eC3IpY+jvx8umtAVELZIfpWW8zobK0OFk=";
    })
    (fetchurl {
      url = "https://github.com/intel/intel-graphics-compiler/releases/download/v2.14.1/intel-igc-opencl-2_2.14.1+19448_amd64.deb";
      hash = "sha256-9SsTQo0DT/njq9cvcSffr1pM5vCuFuvi9etD9Letw2Y=";
    })
    (fetchurl {
      url = "https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/intel-opencl-icd_25.27.34303.5-0_amd64.deb";
      hash = "sha256-5GSZ/X+goFZ1m1JCW2uijlqmc0/0a80eH4VBxe/C4LM=";
    })
    (fetchurl {
      url = "https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/libigdgmm12_22.7.2_amd64.deb";
      hash = "sha256-aPnmx5wpi/dagCU63vLoS/ABHcPnDbPnLap+StRvlc8=";
    })
    (fetchurl {
      url = "https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/libze-intel-gpu1_25.27.34303.5-0_amd64.deb";
      hash = "sha256-TgjTeWyFZQXIUvhwD0S3iVzRhcSOg+vFeF2XRLYANUY=";
    })
  ];
  dontStrip = true;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    zstd
  ];

  unpackPhase = ''
    for src in $srcs; do
      dpkg-deb -x "$src" .
    done
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib
    find . -name 'ocloc*' -exec cp {} $out/bin/ \;
    find . -name '*.so*' -exec cp {} $out/lib/ \;
    mv $out/bin/ocloc-${finalAttrs.version}* $out/bin/ocloc
    runHook postInstall
  '';

  # Some libraries like libigc.so are dlopen'ed from other shared
  # libraries in the package. So we need to add the library path
  # to RPATH. Ideally we'd want to use
  #
  # runtimeDependencies = [ (placeholder "out") ];
  #
  # But it only adds the dependency to binaries, not shared
  # libraries, so we hack around it here.
  doInstallCheck = true;
  preInstallCheck = ''
    patchelf --add-rpath ${placeholder "out"}/lib $out/lib/*.so*
  '';
})
