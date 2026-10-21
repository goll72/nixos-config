{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "tab-reload-notify-native";
  version = "0.2";

  src = fetchFromGitHub {
    owner = "goll72";
    repo = "tab-reload-notify";
    tag = "v${finalAttrs.version}";
    hash = "sha256-giTt9h1zOeLpoGaL1eBh2BbmW3xzrrZZqN9DJuWlAUs=";
  };

  cargoRoot = "native/notify-server";
  buildAndTestSubdir = "native/notify-server";

  # Upstream uses nightly feature gates (read_buf, btree_cursors); nixpkgs
  # only ships stable rustc, so opt into feature gates on stable.
  RUSTC_BOOTSTRAP = "1";

  cargoHash = "sha256-9KnCjUUlnzrs1UXCJxSqNGmwDBGBkpbLKWHQGEzjOOs=";

  # The manifest is generated from native/native-manifest.json.in, matching
  # the substitution performed by scripts/gen-installer.sh for Firefox.
  postInstall = ''
        mkdir -p $out/lib/mozilla/native-messaging-hosts
        cat > $out/lib/mozilla/native-messaging-hosts/tab_reload_notify_server.json <<EOF
    {
        "name": "tab_reload_notify_server",
        "description": "file watch server for the tab-reload-notify extension",
        "path": "$out/bin/notify-server",
        "type": "stdio",
        "allowed_extensions": ["tab_reload_notify@goll.cc"]
    }
    EOF
  '';

  meta = {
    description = "Native messaging host for the tab-reload-notify Firefox extension";
    homepage = "https://github.com/goll72/tab-reload-notify";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "notify-server";
  };
})
