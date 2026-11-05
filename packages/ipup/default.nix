{
  lib,
  stdenv,
  fetchFromGitHub,
  inih,
  ldns,
  libnl,
  meson,
  ninja,
  openssl,
  pkg-config,
}:

stdenv.mkDerivation {
  pname = "ipup";
  # No tags upstream; version is from meson.build, date is the pinned commit.
  version = "0.1-unstable-2026-11-05";

  src = fetchFromGitHub {
    owner = "goll72";
    repo = "ipup";
    rev = "d71f08ef94c784948537af171d8fadecef8fee4b";
    hash = "sha256-A9QPfIf9GNkzOKm3EEOmU52DNgq9Vp+v9h8+9l7PCSA=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    inih
    # ldns headers include <openssl/ssl.h> unconditionally (DANE).
    openssl
    ldns
    libnl
  ];

  mesonFlags = [
    # Look for the system config in /etc/ipup/conf instead of
    # /usr/local/etc/ipup/conf.
    "-Dsysconfdir=/etc"
  ];

  meta = {
    description = "IP update tool that tracks address changes via Netlink and updates DNS records with RFC 2136";
    homepage = "https://github.com/goll72/ipup";
    license = lib.licenses.bsd2;
    mainProgram = "ipup";
    platforms = lib.platforms.linux;
  };
}
