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

  # Local dnsmasq resolver; on the hub (lambda) this is also the
  # VPN's DNS server.
  services.local-dns.enable = true;

  environment.enableAllTerminfo = true;

  services.vpn.wireguard.backend = "wireguard";

  services.openiscsi = {
    enable = true;
    name = "iqn.${meta.domainCreatedAt}.${domainReversed}:${hostname}";
  };

  services.journald.settings.Journal.SystemMaxUse = "100M";

  security.sudo.wheelNeedsPassword = false;
}
