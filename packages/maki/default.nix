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
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "tontinton";
    repo = "maki";
    tag = "v${finalAttrs.version}";
    hash = "sha256-XKF7V4p3He4TR6GGvclLzvhTGvHxxp92OB955VKLVXE=";
  };

  cargoHash = "sha256-H/LuhS6tGgYnlxTV3wCSh18xsDnjQ6QAss9r2ChDKdo=";

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
