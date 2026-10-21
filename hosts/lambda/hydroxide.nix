{
  config,
  meta,
  ...
}:

{
  sops.templates."hydroxide-env".content = ''
    HYDROXIDE_BRIDGE_PASS=${config.sops.placeholder."hydroxide-bridge-pass"}
  '';

  services.hydroxide = {
    enable = true;
    useACME = true;

    domain = meta.domain;

    environmentFile = config.sops.templates."hydroxide-env".path;
  };
}
