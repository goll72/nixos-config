{
  lib,
  rustPlatform,
  fetchFromGitHub,
  applyPatches,
  runCommand,
  installShellFiles,
  versionCheckHook,
  lockedGrammars ? lib.importJSON ./grammars.json,
  grammarsOverlay ? import ./grammars-overlay.nix,
}:

let
  rev = "70e01632289b55670cd405f0b04c818af3f8128c";

  # Apply the PR patches to the source up front so the cargo vendor output and
  # the build see the same Cargo.lock.
  src = applyPatches {
    src = fetchFromGitHub {
      owner = "thdxg";
      repo = "helix";
      inherit rev;
      hash = "sha256-IBwEcgLUAnelFmU6MS6CuN9o+q6x1FDas1o9TZH3Vq4=";
    };

    patches = [
      ./patches/0001-13760-jump-to-label-label-gen-prefer-lower-chars.patch
      ./patches/0002-13988-swap-splits-with-shift-arrow.patch
      ./patches/0003-7988-inactive-pane-background.patch
      ./patches/0004-8546-flex-resize-and-focus-mode.patch
      ./patches/0005-11695-match-in-next-previous-char-pairs.patch
      ./patches/0006-12043-case-conversion-commands.patch
      ./patches/0007-12208-hover-dump-goto-hover.patch
      ./patches/0008-13113-disambiguate-buffer-names.patch
      ./patches/0009-14072-rewrite-bufferline-rendering.patch
      ./patches/0010-12173-click-bufferline-to-switch-buffers.patch
      ./patches/0011-15573-breadcrumb-navigation.patch
      ./patches/0012-15599-accurate-grapheme-width-calculation.patch
      ./patches/0013-16429-match-bracket-node-under-cursor.patch
      ./patches/0014-16339-render-control-chars-safely.patch
      ./patches/0015-scroll-hint-exclude-bufferline.patch
      ./patches/0016-fold-highlight-range.patch
      ./patches/0017-fold-keep-continuation.patch
    ];
  };
in
rustPlatform.buildRustPackage (
  finalAttrs:
  let
    defaultRuntimeDir = runCommand "helix-default-runtime" { } ''
      cp -r --no-preserve=mode ${finalAttrs.src}/runtime $out
      rm -rf $out/grammars $out/queries
    '';
  in
  {
    pname = "helix-unwrapped";
    version = "25.07.1";

    inherit src;

    cargoHash = "sha256-bdQCuQiVzJUEtR9ilyMlgPomuKPZrZRoL92JN/tTp1M=";

    nativeBuildInputs = [
      installShellFiles
    ];

    env = {
      # Disable fetching and building tree-sitter grammars in helix-term's build.rs.
      HELIX_DISABLE_AUTO_GRAMMAR_BUILD = "1";
      HELIX_DEFAULT_RUNTIME = defaultRuntimeDir;
      HELIX_NIX_BUILD_REV = rev;
    };

    doCheck = false;
    strictDeps = true;

    postInstall = ''
      installShellCompletion contrib/completion/hx.{bash,fish,zsh}
      mkdir -p $out/share/{applications,icons/hicolor/256x256/apps}
      cp contrib/Helix.desktop $out/share/applications/Helix.desktop
      cp contrib/helix.png $out/share/icons/hicolor/256x256/apps/helix.png
    '';

    nativeInstallCheckInputs = [
      versionCheckHook
    ];

    versionCheckProgram = "${placeholder "out"}/bin/hx";
    doInstallCheck = true;

    # Expose the tree-sitter grammar lockfile and overlay so the overlay in
    # `overlays/packages.nix` can hand them to nixpkgs' `helix` wrapper, which
    # builds the grammars into the runtime (`HELIX_RUNTIME`).  This is what
    # actually gets tree-sitter highlighting working for the fork.
    passthru = {
      inherit lockedGrammars grammarsOverlay;
    };

    meta = {
      description = "Post-modern modal text editor (thdxg Steel fork)";
      homepage = "https://github.com/thdxg/helix";
      changelog = "https://github.com/thdxg/helix/commits/${rev}";
      license = lib.licenses.mpl20;
      mainProgram = "hx";
      maintainers = with lib.maintainers; [
        aciceri
        yusdacra
      ];
    };
  }
)
