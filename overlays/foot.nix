final: prev: {
  foot = prev.foot.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace $out/share/applications/foot.desktop \
        --replace-fail 'Icon=foot' 'Icon=utilities-terminal'
    '';
  });
}
