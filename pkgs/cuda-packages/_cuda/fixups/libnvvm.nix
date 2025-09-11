{ }:
prevAttrs: {
  outputs = [ "out" ];

  # NOTE: ideally, we would flatten libnvvms directory structure,
  # since we will have nvvm/{bin,include,lib64,libdevice} in the
  # output. However, e.g. CMake expects nvvm/libdevice to be a
  # valid path.
}
