{
  stdenv,
  fetchzip,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "metal-cpp";

  # TODO: update to version 26 when metal compiler support is resolved
  # version = "26";

  version = "17.4";
  outputs = [
    "out"
    "dev"
    "doc"
  ];
  outputBin = "dev";

  src = fetchzip {
    # TODO: update URL when version is updated
    # url = "https://developer.apple.com/metal/cpp/files/${pname}_${version}.zip";

    url = "https://developer.apple.com/metal/cpp/files/${pname}_macOS${version}_iOS${version}.zip";
    hash = "sha256-7n2eI2lw/S+Us6l7YPAATKwcIbRRpaQ8VmES7S8ZjY8=";
    stripRoot = true;
  };

  phases = [
    "installPhase"
  ];

  installPhase = ''
    runHook preInstall
    # Create output directories
    mkdir -p "$out" "$dev/include" "$doc/share/doc/${pname}"
    # Copy framework headers
    cp -r "$src"/{Foundation,Metal,MetalFX,QuartzCore,SingleHeader} "$dev/include/"
    # Copy documentation files
    install -Dm644 "$src"/{README.md,LICENSE.txt} -t "$doc/share/doc/${pname}"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Header-only C++ interface for the Apple Metal framework";
    homepage = "https://developer.apple.com/metal/cpp/";
    platforms = platforms.darwin;
  };
}
