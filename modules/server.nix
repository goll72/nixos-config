{
  lib,
  lib',
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

  # The local resolver prepends 127.0.0.1/::1 to resolv.conf via
  # openresolv (useLocalResolver is set by the local-dns module).
  services.local-dns.enable = true;
  services.knot-zone-watch.enable = true;

  environment.enableAllTerminfo = true;

  services.wireguard-vpn = lib'.wireguardVpnPeers "wireguard";

  services.openiscsi = {
    enable = true;
    name = "iqn.${meta.domainCreatedAt}.${domainReversed}:${hostname}";
  };

  services.journald.settings.Journal.SystemMaxUse = "100M";

  security.sudo.wheelNeedsPassword = false;
}
