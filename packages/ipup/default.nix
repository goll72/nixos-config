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
  version = "0.1-unstable-2026-10-12";

  src = fetchFromGitHub {
    owner = "goll72";
    repo = "ipup";
    rev = "48930df21ed85cf72004f4d71f9d390034a3411a";
    hash = "sha256-e/kAUk7xCHk++PE7HX6K1VMp5nW0jVCLfxRE9LlRUO0=";
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
