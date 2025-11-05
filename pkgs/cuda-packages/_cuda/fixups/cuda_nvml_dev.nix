{ lib }:
prevAttrs: {
  outputs =
    prevAttrs.outputs or [ ]
    ++ lib.lists.optionals (!(builtins.elem "stubs" prevAttrs.outputs)) [ "stubs" ];

  # TODO(@connorbaker): Add a setup hook to the outputStubs output to automatically replace rpath entries
  # containing the stubs output with the driver link.

  allowFHSReferences = true;

  # Include the stubs output since it provides libnvidia-ml.so.
  propagatedBuildOutputs = [ "stubs" ];

  # TODO: Some programs try to link against libnvidia-ml.so.1, so make an alias.
  # Not sure about the version number though!
  postFixup = prevAttrs.postFixup or "" + ''
    moveToOutput lib/stubs "$stubs"
    ln -s "$stubs"/lib/stubs/* "$stubs"/lib/
    mkdir -p ''${!outputLib}/lib
    ln -s "$stubs"/lib/stubs "''${!outputLib}/lib/stubs"
  '';
}
