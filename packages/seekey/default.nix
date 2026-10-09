{
  lib,
  stdenv,
  fetchFromGitHub,
  gettext,
  glib,
  gtk4,
  gtk4-layer-shell,
  json-glib,
  libevdev,
  makeWrapper,
  ncurses,
  pkg-config,
}:

stdenv.mkDerivation {
  pname = "seekey";
  version = "0.3.0";

  # Build the local tree (flake source = git-tracked files).  A pinned
  # fetchFromGitHub would silently ship the last release instead of local
  # changes; bump the pin only when releasing.
  src = fetchFromGitHub {
    owner = "Nakanomk";
    repo = "Seekey";
    rev = "625c459ac3ad4c81134050f5f74b0c7e146c8eed";
    hash = "sha256-ln/77IRcppWf3yCaKBkbt0P1BeKf0ZwFRyqcIKD+ZfQ=";
  };

  patches = [
    # Add support for running as a regular user and elevating privileges using pkexec
    ./0001-add-pkexec-support.patch
    # Add support for the br keyboard layout (hardcoded)
    ./0002-br-keyboard-layout.patch
  ];

  buildInputs = [
    glib
    gtk4
    gtk4-layer-shell
    json-glib
    libevdev
    ncurses
  ];

  nativeBuildInputs = [
    makeWrapper
    pkg-config

    gettext
  ];

  installPhase = ''
    make PREFIX=$out install
  '';

  meta = {
    description = "A tool to show your key inputs on wayland";
    homepage = "https://github.com/Nakanomk/Seekey";
    license = [ lib.licenses.mit ];
  };
}
