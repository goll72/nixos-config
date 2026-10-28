final: prev: {
  hylki = prev.callPackage ../packages/hylki { };
  ipup = prev.callPackage ../packages/ipup { };
  pawse = prev.callPackage ../packages/pawse { };
  seekey = prev.callPackage ../packages/seekey { };
  tab-reload-notify-native = prev.callPackage ../packages/tab-reload-notify-native { };
  zerostack = prev.callPackage ../packages/zerostack { };

  gnomeExtensions = prev.gnomeExtensions // {
    # PR #170 (fix for blurry overview previews, gnome-shell#7903);
    # drop this override once it lands upstream and nixpkgs picks it up.
    rounded-window-corners-reborn =
      prev.callPackage ../packages/gnome-extension-rounded-window-corners-reborn
        { };
    wiggle = prev.callPackage ../packages/gnome-extension-wiggle { };
  };
}
