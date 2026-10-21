# XXX: remove this file once hylki gets merged in nixpkgs upstream

{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  dbus,
  glib,
  gpgme,
  gtk4,
  libadwaita,
  libgpg-error,
  libsoup_3,
  openssl,
  poppler,
  shared-mime-info,
  sqlite,
  webkitgtk_6_0,
  gsettings-desktop-schemas,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "hylki";
  version = "1.43.2";

  src = fetchFromGitHub {
    owner = "hyprlab";
    repo = "hylki";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ek48CoW64hqa2V0FRU3TvGrWF1FVSyxzhndZ3o3aP2k=";
  };

  cargoHash = "sha256-V/ASBtVXffdbx39JUl0qJdZH74p0kh9ZZ4cIQujqkVc=";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    # build.rs calls glib_build_tools::compile_resources for the icon,
    # sender-logo and notification-sound gresource bundles.
    glib
    shared-mime-info
  ];

  buildInputs = [
    dbus
    glib
    gpgme
    gtk4
    gsettings-desktop-schemas
    libadwaita
    libgpg-error
    libsoup_3
    openssl
    poppler
    sqlite
    webkitgtk_6_0
  ];

  # NOTE: RAM usage from tests is too high
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  postInstall = ''
    mkdir -p "$out/share/icons"

    for i in data/icons/*; do
      [ -e "$i" ] || continue
      cp -R -t "$out/share/icons" "$i"
    done

    find "$out/share/icons" -type d -exec chmod 555 '{}' \;
    find "$out/share/icons" -type f -exec chmod 444 '{}' \;

    for d in data/*.desktop; do
      [ -e "$d" ] || continue
      install -Dm444 "$d" "$out/share/applications/$(basename "$d")"
    done

    for g in data/*.gschema.xml; do
      [ -e "$g" ] || continue
      install -Dm444 "$g" "$out/share/glib-2.0/schemas/$(basename "$g")"
    done
  '';

  meta = {
    description = "GNOME-native email client built with Rust and libadwaita";
    homepage = "https://hyprlab.co/hylki/";
    changelog = "https://github.com/hyprlab/hylki/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.agpl3Plus;
    mainProgram = "hylki";
    platforms = lib.platforms.linux;
  };
})
