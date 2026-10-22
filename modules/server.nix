{
  lib,
  config,
  meta,
  ...
}:

let
  hostname = config.networking.hostName;

  domainReversed = lib.concatStringsSep "." (
    lib.lists.reverseList (lib.strings.splitString "." meta.domain)
  );
in
{
  networking.firewall.enable = false;

  environment.enableAllTerminfo = true;

  services.wireguard-vpn.backend = "wireguard";

  services.openiscsi = {
    enable = true;
    name = "iqn.${meta.domainCreatedAt}.${domainReversed}:${hostname}";
  };

  services.journald.settings.Journal.SystemMaxUse = "100M";

  security.sudo.wheelNeedsPassword = false;
}
