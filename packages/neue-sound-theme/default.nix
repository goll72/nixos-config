{
  stdenvNoCC,
  ...
}:

stdenvNoCC.mkDerivation {
  pname = "neue-sound-theme";
  version = "1.0";

  src = ../../assets/sounds/neue;

  installPhase = ''
    mkdir -p $out/share/sounds
    cp -R $src $out/share/sounds/neue
  '';
}
