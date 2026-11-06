final: prev: {
  # thdxg's Steel-based Helix fork with selected upstream PRs applied.
  helix-unwrapped = prev.callPackage ../packages/helix { };

  helix = prev.helix.override {
    inherit (final) helix-unwrapped;
  };

  hylki = prev.callPackage ../packages/hylki { };
  ipup = prev.callPackage ../packages/ipup { };
  maki = prev.callPackage ../packages/maki { };
  neue-sound-theme = prev.callPackage ../packages/neue-sound-theme { };
  pawse = prev.callPackage ../packages/pawse { };
  seekey = prev.callPackage ../packages/seekey { };
  tab-reload-notify-native = prev.callPackage ../packages/tab-reload-notify-native { };

  gnomeExtensions = prev.gnomeExtensions // {
    # PR #170 (fix for blurry overview previews, gnome-shell#7903);
    # drop this override once it lands upstream and nixpkgs picks it up.
    rounded-window-corners-reborn =
      prev.callPackage ../packages/gnome-extension-rounded-window-corners-reborn
        { };
    wiggly = prev.callPackage ../packages/gnome-extension-wiggly { };
  };
}
