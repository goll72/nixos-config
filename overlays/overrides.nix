final: prev: {
  # Foot: point the desktop file's icon at the generic terminal icon instead of
  # the `foot` icon (a picture of a foot) so it matches other entries.
  foot = prev.foot.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace $out/share/applications/foot.desktop \
        --replace-fail 'Icon=foot' 'Icon=utilities-terminal'
    '';
  });

  # CAPTCHA support for `hydroxide auth`, sourced from the Jahroots fork
  # https://github.com/Jahroots/hydroxide (master @ 60a7c7e, 2026-07-29).
  # The vendored patch is exactly that fork's delta against our base rev —
  # byte-identical to PR https://codeberg.org/emersion/hydroxide/pulls/358
  # commit 1. We deliberately do not carry the PR's later commits (2-3):
  # they only swap the stdin token-paste fallback for xdg-open and add tests.
  #
  # Drop this override if/once equivalent support is merged upstream and
  # nixpkgs picks it up.
  hydroxide = prev.hydroxide.overrideAttrs (old: {
    # NOTE: go.mod/go.sum are identical to v0.2.32, so we don't need to override nixpkgs's vendorHash
    version = "${old.version}-unstable-2026-08-03";

    src = prev.fetchurl {
      url = "https://codeberg.org/emersion/hydroxide/archive/80aa6c315cdd378207b6d44d6014240b3a636449.tar.gz";
      hash = "sha256-njdHNyfy6SgKOkRzlUpq3l443SJkuQWB4cTq35qnTFs=";
    };

    patches = (old.patches or [ ]) ++ [ ./patches/hydroxide-auth-captcha.patch ];
  });
}
