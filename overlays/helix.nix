# This overlay is not included by default, to avoid having to compile Helix in some hosts.

final: prev: {
  # thdxg's Steel-based Helix fork with a few extra upstream PRs applied.
  helix-unwrapped = prev.callPackage ../packages/helix { };

  helix = prev.helix.override {
    helix-unwrapped = final.helix-unwrapped;
    lockedGrammars = final.helix-unwrapped.passthru.lockedGrammars;
    grammarsOverlay = final.helix-unwrapped.passthru.grammarsOverlay;
  };
}
