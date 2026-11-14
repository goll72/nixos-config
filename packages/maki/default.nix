{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  perl,
  python3,
  openssl,
  dbus,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "maki";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "tontinton";
    repo = "maki";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Jtpi75JH2LIlrfNTVDwePYNqVuBYRPGyG/f1aZuTmUw=";
  };

  cargoHash = "sha256-5+hgRI3XyPdRcefSokYUXHrgjp2k8i1+9D3lCujm9uk=";

  # unpinCargoMsrvHook: upstream pins rust-version = "1.99", newer than the
  # rustc in nixpkgs.
  nativeBuildInputs = [
    pkg-config
    perl
    python3
  ];

  buildInputs = [ openssl ] ++ lib.optionals stdenv.hostPlatform.isLinux [ dbus ];

  env = {
    # isahc's native-tls-static would otherwise build OpenSSL from source.
    OPENSSL_NO_VENDOR = "1";
  };

  cargoBuildFlags = [
    "--package"
    "maki"
  ];

  doCheck = false;

  meta = {
    description = "Efficient AI coding agent extendable by neovim-like Lua plugins";
    homepage = "https://maki.sh";
    changelog = "https://github.com/tontinton/maki/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ colemickens ];
    mainProgram = "maki";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = lib.platforms.unix;
  };
})
