# XXX: remove once https://gitlab.gnome.org/GNOME/gnome-shell/-/work_items/7903 is fixed

{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  glib,
  gettext,
}:

buildNpmPackage {
  pname = "gnome-shell-extension-rounded-window-corners-reborn";
  # EGO v25 plus https://github.com/flexagoon/rounded-window-corners/pull/170,
  # which fixes blurry window previews in the overview (gnome-shell#7903).
  version = "25-unstable-2026-08-11";

  src = fetchFromGitHub {
    owner = "flexagoon";
    repo = "rounded-window-corners";
    rev = "9a28ba47a82c0427d79fc0cbf9c50f4cc16d1c2c";
    hash = "sha256-NP7Zc3McmPU2mMU7eZl+myb0PnZWvSM7YjFeMdlxhW8=";
  };

  npmDepsHash = "sha256-r15ZN9PFMWvdrkLd/0meT2WXYk4StGxltZQZBQ09Q2Q=";

  nativeBuildInputs = [
    glib
    gettext
  ];

  # Mirrors the justfile `build` target: compile TypeScript, then copy
  # every non-JS file from resources/ and src/ next to the output.
  buildPhase = ''
    runHook preBuild

    npx tsc

    cp -r resources/* _build/
    while IFS= read -r f; do
      rel=''${f#src/}
      mkdir -p "_build/$(dirname "$rel")"
      cp "$f" "_build/$rel"
    done < <(find src -type f ! -name '*.ts')

    runHook postBuild
  '';

  # Mirrors the justfile `install` target, minus the copy into $HOME.
  installPhase = ''
    runHook preInstall

    glib-compile-schemas --strict _build/schemas

    for po in po/*.po; do
      locale=$(basename "$po" .po)
      mkdir -p "_build/locale/$locale/LC_MESSAGES"
      msgfmt -o "_build/locale/$locale/LC_MESSAGES/rounded-window-corners@fxgn.mo" "$po"
    done

    mkdir -p "$out/share/gnome-shell/extensions/rounded-window-corners@fxgn"
    cp -rT _build "$out/share/gnome-shell/extensions/rounded-window-corners@fxgn"

    runHook postInstall
  '';

  passthru = {
    extensionUuid = "rounded-window-corners@fxgn";
    extensionPortalSlug = "rounded-window-corners-reborn";
  };

  meta = {
    description = "GNOME Shell extension that adds rounded corners to all windows";
    homepage = "https://github.com/flexagoon/rounded-window-corners";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
