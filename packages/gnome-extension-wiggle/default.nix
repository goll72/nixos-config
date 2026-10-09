{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  glib,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gnome-shell-extension-wiggle";
  version = "5-unstable-2025-03-28";

  src = fetchFromGitHub {
    owner = "mechtifs";
    repo = "wiggle";
    rev = "db1bec361d292ae0c465eca25db4854e422ad5e4";
    hash = "sha256-9w5JyRrCpdYnEiCaNkjqhe9fWDMP5PX5VUn1YfqxVLw=";
  };

  patches = [
    # PR #27: cursor tracker API changes for GNOME 46-49
    # (https://github.com/mechtifs/wiggle/pull/27)
    ./0001-add-gnome-49-support.patch
    # Declare GNOME Shell 50 as supported
    ./0002-add-gnome-50-support.patch
    # On mutter-17, hiding the cursor makes get_sprite() return null;
    # skip the "hidden by program" check while wiggling so it does not
    # force-unmagnify mid-wiggle. Also fix magnify() ease param.
    ./0003-fix-cursor-check-on-mutter-17.patch
    # Mutter direct-scanouts fullscreen windows, bypassing the stage, so
    # the magnified-cursor icon never paints over them while the hardware
    # cursor is hidden. Inhibit unredirect while magnified.
    ./0004-inhibit-unredirect-while-magnified.patch
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
    cp -rT . $out/share/gnome-shell/extensions/wiggle@mechtifs
    runHook postInstall
  '';

  passthru = {
    extensionUuid = "wiggle@mechtifs";
    extensionPortalSlug = "wiggle";
  };

  meta = {
    description = "GNOME Shell extension that magnifies the cursor when the mouse is moved rapidly";
    homepage = "https://github.com/mechtifs/wiggle";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
})
