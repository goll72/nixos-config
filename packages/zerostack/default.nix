{
  lib,
  rustPlatform,
  fetchFromGitHub,
  binutils,
  mold,
  openssl,
  pkg-config,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "zerostack";
  version = "1.8.5";

  src = fetchFromGitHub {
    owner = "gi-dellav";
    repo = "zerostack";
    tag = "v${finalAttrs.version}";
    hash = "sha256-i6J+7OxXa3tD0Yq/yfHmMPf5kMn51tWvaXYzgRj6YS8=";
  };

  cargoHash = "sha256-zmVbxKETpuFgL9SUb2OCq/t80r2ai1tM/vpu4KhWf24=";

  nativeBuildInputs = [
    binutils
    mold
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  buildFeatures = [
    "multimodal"
    "multithread"
  ];

  doCheck = false;

  meta = {
    description = "Minimalistic coding agent written in Rust, optimized for memory footprint and performance";
    license = lib.licenses.gpl3Only;
    homepage = "https://github.com/gi-dellav/zerostack";
    mainProgram = "zerostack";
    platforms = lib.platforms.linux;
  };
})
