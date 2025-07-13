{
  callPackage,
  fetchFromGitHub,
}:

let
  generic = callPackage ./generic.nix { };
in
{
  aotriton_0_8 = generic rec {
    version = "0.8.2b";

    src = fetchFromGitHub {
      owner = "ROCm";
      repo = "aotriton";
      rev = "${version}";
      hash = "sha256-gSzGYWfyUNLyzqpu3BM8rjFFL7cRVZ+w9L5pnh9QGz4=";
      fetchSubmodules = true;
    };

    gpuTargets = [
      # aotriton GPU support list:
      # https://github.com/ROCm/aotriton/blob/main/v2python/gpu_targets.py
      "gfx90a"
      "gfx942"
      "gfx1100"
      "gfx1101"
    ];
  };

  aotriton_0_9 = generic rec {
    version = "0.9.2b";

    src = fetchFromGitHub {
      owner = "ROCm";
      repo = "aotriton";
      rev = version;
      hash = "sha256-1Cf0olD3zRg9JESD6s/WaGifm3kfD12VUvjTZHpmGAE=";
      fetchSubmodules = true;
    };

    patches = [
      # This was not an issue in 0.8.0b, but appeared when updating to 0.9.xb:
      #   error: non-constant-expression cannot be narrowed from type
      #   'int32_t' (aka 'int') to 'uint32_t' (aka 'unsigned int') in
      #   initializer list [-Wc++11-narrowing]
      ./explicit-cast-for-narrowing.diff
      # Fails with: ld.lld: error: unable to insert .comment after .comment
      ./no-ld-script.diff
    ];

    gpuTargets = [
      "gfx90a"
      "gfx942"
      "gfx950"
      "gfx1100"
      "gfx1151"
      "gfx1201"
    ];
  };

  aotriton_0_10 = generic rec {
    version = "0.10b";

    src = fetchFromGitHub {
      owner = "ROCm";
      repo = "aotriton";
      rev = version;
      hash = "sha256-R5LULmHFP50uI9S228opyg1+1SROxqx1hMPLuATNyoc=";
      fetchSubmodules = true;
    };

    patches = [
      # A bunch of implicit type narrowing issues that are rejected by newer
      # compilers.
      ./v0.10b-explicit-cast-for-narrowing.diff
      # Fails with: ld.lld: error: unable to insert .comment after .comment
      ./v0.10b-no-ld-script.diff
    ];

    gpuTargets = [
      # aotriton GPU support list:
      # https://github.com/ROCm/aotriton/blob/main/v2python/gpu_targets.py
      "gfx90a"
      "gfx942"
      "gfx950"
      "gfx1100"
      "gfx1101"
      "gfx1201"
    ];

    extraPythonDepends = ps: [ ps.pandas ];
  };

}
