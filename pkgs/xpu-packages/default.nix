{
  lib,
  callPackage,
  newScope,
}:

{
  packageMetadata,
}:

let
  # get version of each component
  getVersion =
    namePrefix:
    let
      keys = lib.attrNames packageMetadata;
      matchedKeys = lib.filter (k: builtins.match "(${namePrefix}.*)" k != null) keys;
      pkgKey =
        if matchedKeys != [ ] then builtins.elemAt matchedKeys (builtins.length matchedKeys - 1) else null;
      comps = if pkgKey != null then packageMetadata.${pkgKey}.components or [ ] else [ ];
      found = if comps != [ ] then comps else [ ];
      fullVersion = if found != [ ] then (builtins.head found).version else null;
      shortVersion =
        if fullVersion != null then
          let
            parts = lib.splitString "." fullVersion;
          in
          builtins.concatStringsSep "." [
            (builtins.elemAt parts 0)
            (builtins.elemAt parts 1)
          ]
        else
          null;
    in
    shortVersion;

  dpcppVersion = getVersion "intel-oneapi-dpcpp-cpp-";
  ptiVersion = getVersion "intel-pti-";
  mklVersion = getVersion "intel-oneapi-mkl-";
  tbbVersion = getVersion "intel-oneapi-tbb-";
  ompVersion = getVersion "intel-oneapi-openmp-";

  fixedPoint = final: { inherit callPackage lib packageMetadata; };
  composed = lib.composeManyExtensions [
    # Hooks
    (import ./hooks.nix)
    # Base package set.
    (import ./components.nix)
    # Packages that are joins of other packages.
    (callPackage ./oneapi-torch-dev.nix {
      inherit
        dpcppVersion
        ptiVersion
        mklVersion
        tbbVersion
        ompVersion
        ;
    })

    (final: prev: {
      onednn-xpu = final.callPackage ./onednn-xpu.nix {
        setupXpuHook = final.setupXpuHook;
        oneapi-torch-dev = final.oneapi-torch-dev;
        dpcppVersion = dpcppVersion;
      };
    })
    (final: prev: {
      ocloc = final.callPackage ./ocloc.nix { };
    })
  ];
in
lib.makeScope newScope (lib.extends composed fixedPoint)
