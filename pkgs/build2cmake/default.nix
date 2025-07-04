{
  rustPlatform,
  fetchCrate,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "build2cmake";
  version = "0.5.2";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-Nu4PG5jJhA00kSSqUNaSer9aafqiLoc6IR+6DNqRLRU=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ openssl ];

  cargoHash = "sha256-2xZAlFUDfM8FH/zBEQ77cTTy5Wu8V+uYHG2ZrwJQa7s=";

  meta = {
    description = "Converts build.toml to CMake";
  };
}
