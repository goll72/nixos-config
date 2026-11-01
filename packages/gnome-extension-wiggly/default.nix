{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  glib,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gnome-shell-extension-wiggly";
  version = "8-unstable-2026-06-14";

  src = fetchFromGitHub {
    owner = "Arch-Lover";
    repo = "wiggly";
    rev = "a8a608b51e4ee6c01eeb01e001a223bf7ae16d7d";
    hash = "sha256-0ckNhZVlwngDEJIn6EKGofEIUt6RN0w8kWJvJM7pgKA=";
  };

  patches = [
    # On mutter-17 (GNOME 49+), hiding the cursor makes get_sprite()
    # return null; skip the "hidden by program" check while wiggling so
    # it does not force-unmagnify mid-wiggle.
    ./0001-fix-skip-cursor-hidden-check-while-wiggling-on-mutte.patch
    # Mutter direct-scanouts fullscreen windows, bypassing the stage, so
    # the magnified-cursor icon never paints over them while the hardware
    # cursor is hidden. Inhibit unredirect while magnified.
    ./0002-fix-inhibit-unredirect-while-magnified-so-the-icon-p.patch
    # Hiding/inhibiting the cursor aborts an in-progress window
    # move/resize grab, so never magnify while dragging or resizing.
    ./0003-fix-do-not-magnify-the-cursor-while-dragging-or-resi.patch
  ];

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    if [ -d schemas ]; then
      glib-compile-schemas --strict schemas
    fi
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -rT . $out/share/gnome-shell/extensions/wiggly@mojarch
    runHook postInstall
  '';

  passthru = {
    extensionUuid = "wiggly@mojarch";
    extensionPortalSlug = "wiggly";
  };

  meta = {
    description = "GNOME Shell extension that magnifies the cursor when the mouse is moved rapidly";
    homepage = "https://github.com/Arch-Lover/wiggly";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
})
