{ lib, cudaAtLeast }:
prevAttrs: {
  # Flatten to work with existing includes.
  prePatch =
    prevAttrs.prePatch or ""
    + lib.optionalString (cudaAtLeast "13.0") ''
      rm -rf include/nv
      mv include/cccl/* include/
      rmdir include/cccl
    '';
}
