{
  lib,
  meta,
  config,
  ...
}:

let
  hostname = config.networking.hostName;

  domainReversed = lib.concatStringsSep "." (
    lib.lists.reverseList (lib.strings.splitString "." meta.domain)
  );
in
{
  networking.useDHCP = true;

  networking.firewall.enable = false;
  networking.resolvconf.useLocalResolver = false;

  environment.enableAllTerminfo = true;

  services.wireguard-vpn = {
    phi = {
      name = "phi.net";
      interface = "wg.phi";
      backend = "wireguard";
      privateKeySecret = "wg-key";
    };

    lambda = {
      name = "lambda.net";
      interface = "wg.lambda";
      backend = "wireguard";
      privateKeySecret = "wg-key";
    };
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.${meta.domainCreatedAt}.${domainReversed}:${hostname}";
  };

  services.journald.settings.Journal.SystemMaxUse = "100M";

  security.sudo.wheelNeedsPassword = false;
}
