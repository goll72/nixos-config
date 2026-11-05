{
  lib,
  stdenv,
  kernel,
  buildPackages,
}:

let
  modulePath = "sound/hda/codecs";
  moduleName = "snd-hda-codec-conexant";

  # nixpkgs 26.11+ requires a .ko.cer next to every external module.
  # Older nixpkgs has no kmodigest, so signing is skipped there.
  signModules =
    buildPackages:
    lib.optionalString (buildPackages ? kmodigest) ''
      find $out/lib/modules -name '*.ko' -exec ${lib.getExe buildPackages.kmodigest} {} \;
    '';

in
stdenv.mkDerivation {
  pname = "linux-hda-codec-conexant";

  inherit (kernel)
    src
    version
    patches
    postPatch
    nativeBuildInputs
    ;

  dontConfigure = true;

  buildPhase = ''
    BUILT_KERNEL=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build

    cp $BUILT_KERNEL/Module.symvers .
    cp $BUILT_KERNEL/.config .
    cp ${kernel.dev}/vmlinux .

    make -j$NIX_BUILD_CORES modules_prepare
    make -j$NIX_BUILD_CORES M="${modulePath}" ${moduleName}.ko
  '';

  installPhase = ''
    INSTALL_DIR="$out/lib/modules/${kernel.modDirVersion}/updates/${modulePath}"

    install -D -m644 \
      "${modulePath}/${moduleName}.ko" \
      "$INSTALL_DIR/${moduleName}.ko"
  '';

  postFixup = signModules buildPackages;

  meta = {
    description = "Linux HD-audio codec drivers";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
