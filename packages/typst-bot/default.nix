{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "typst-bot";
  version = "0-unstable-2026-09-18";

  src = fetchFromGitHub {
    owner = "mattfbacon";
    repo = "typst-bot";
    rev = "f614708503ff15e5b7d1635aff7c555091bf84cd";
    hash = "sha256-5G1qaxPiNxjRx2V+hyVbaqHT2hfDHeu+8LvOK6xytEs=";
  };

  cargoHash = "sha256-OMVKzyaoODDyn1M6A4ulgEcGLw2QhDOK7rua2GAZts4=";

  cargoBuildFlags = [ "--workspace" ];

  postPatch = ''
    cat > crates/bot/build.rs <<'EOF'
    fn main() {
        println!("cargo:rustc-env=BUILD_SHA=${finalAttrs.src.rev}");
    }
    EOF
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 target/release/bot \
      $out/bin/bot
    install -Dm755 target/release/worker \
      $out/bin/worker

    runHook postInstall
  '';

  meta = {
    description = "A discord bot to render Typst code";
    homepage = "https://github.com/mattfbacon/typst-bot";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
  };
})
