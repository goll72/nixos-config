{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  clang,
  makeBinaryWrapper,

  nodejs,
  fetchNpmDeps,
  npmHooks,

  alsa-lib,
  fontconfig,
  freetype,
  wayland,
  libxkbcommon,
  libxcb,
  libx11,
  libxext,
  dbus,
  vulkan-loader,
  libGL,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pawse";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "popovpsk";
    repo = "pawse";
    tag = "v${finalAttrs.version}";
    hash = "sha256-lRlUuyyX/w3UZbOZgsm+d5b+R5B0VRt72NIRD9gFmJ4=";
  };

  patches = [
    # Allow selecting a 512 MB network cache limit (upstream's smallest option is 1 GB).
    ./0001-allow-512m-network-cache-limit.patch
  ];

  # The Cargo.lock lives inside the fetched source; reading it during evaluation is
  # import-from-derivation but keeps the lockfile pinned upstream rather than vendored here.
  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

  # The remote-control web UI is embedded into the binary via rust-embed and must be
  # built before cargo, or the embedded assets are empty.
  npmDeps = fetchNpmDeps {
    name = "pawse-web-npm-deps";
    src = "${finalAttrs.src}/web";
    hash = "sha256-gNtpqIV6rRvWYY7hk7Wq5M+X6uAmOlZVs2dytu2FPLU=";
  };

  nativeBuildInputs = [
    pkg-config
    cmake
    # aws-lc-sys and gpui's bindgen usage need libclang at build time.
    clang
    rustPlatform.bindgenHook
    makeBinaryWrapper
    npmHooks.npmConfigHook
    nodejs
  ];

  # The embedded web UI lives under web/; point the npm hook there.
  npmRoot = "web";

  buildInputs = [
    alsa-lib
    fontconfig
    freetype
    wayland
    libxkbcommon
    libxcb
    libx11
    libxext
    dbus
  ];

  # Build only the app binary, not the whole workspace's tests/dev tooling.
  cargoBuildFlags = [ "--package=pawse" ];

  # The workspace pulls in heavy crates whose tests don't apply here.
  doCheck = false;

  # The app checks for upstream releases to self-update; that can't work from the
  # Nix store, so tell it updates are disabled instead of failing at runtime.
  env.ZED_UPDATE_EXPLANATION = "Pawse has been installed with Nix, so auto-updates are disabled.";

  postInstall = ''
    install -Dm644 ${finalAttrs.src}/packaging/flatpak/io.github.popovpsk.pawse.desktop \
      $out/share/applications/io.github.popovpsk.pawse.desktop
    install -Dm644 ${finalAttrs.src}/packaging/flatpak/io.github.popovpsk.pawse.metainfo.xml \
      $out/share/metainfo/io.github.popovpsk.pawse.metainfo.xml
    install -Dm644 crates/ui_resources/assets/app-icon/32x32.png \
      $out/share/icons/hicolor/32x32/apps/io.github.popovpsk.pawse.png
    install -Dm644 crates/ui_resources/assets/app-icon/128x128.png \
      $out/share/icons/hicolor/128x128/apps/io.github.popovpsk.pawse.png
    install -Dm644 crates/ui_resources/assets/app-icon/256x256.png \
      $out/share/icons/hicolor/256x256/apps/io.github.popovpsk.pawse.png

    # GPUI dlopens libvulkan and libGL at runtime for rendering.
    wrapProgram $out/bin/pawse \
      --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ vulkan-loader libGL ]}
  '';

  meta = {
    description = "Fast, native music player for your local library, built in Rust and GPUI";
    homepage = "https://github.com/popovpsk/pawse";
    license = lib.licenses.mit;
    mainProgram = "pawse";
    platforms = lib.platforms.linux;
  };
})
