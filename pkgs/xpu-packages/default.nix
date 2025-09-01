{
  lib,
  callPackage,
  newScope,
}:

{
  packageMetadata,
}:

let
  fixedPoint = final: { inherit callPackage lib packageMetadata; };
  composed = lib.composeManyExtensions [
    # Hooks
    (import ./hooks.nix)
    # Base package set.
    (import ./components.nix)
    # Overrides (adding dependencies, etc.)
    (import ./overrides.nix)
    # Packages that are joins of other packages.
    (final: prev: {
      oneapi-torch-dev = final.callPackage ./oneapi-torch-dev.nix { };
    })

    (final: prev: {
      onednn-xpu = final.callPackage ./onednn-xpu.nix {
        setupXpuHook = final.setupXpuHook;
        oneapi-torch-dev = final.oneapi-torch-dev;
      };
    })
    (final: prev: {
      ocloc = final.callPackage ./ocloc.nix { };
    })
  ];
in
lib.makeScope newScope (lib.extends composed fixedPoint)
