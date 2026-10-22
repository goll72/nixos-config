# The DNS server for the Wireguard VPN, run on the hub only (asserted
# below): a dnsmasq instance bound to the hub's tunnel addresses, where
# the VPN clients point their resolver, and to localhost, where it
# doubles as the hub host's own resolver (prepended via openresolv).
#
# Requests under the internal domain are answered from the hosts file,
# requests for our public domain go to the local knotd (or, on hosts
# that aren't authoritative, to the public IPs of the authoritative
# servers) and everything else to select public DNS servers.

{
  lib,
  lib',
  config,
  meta,
  pkgs,
  ...
}:

let
  cfg = config.services.vpn-dns;
  thisHost = config.networking.hostName;

  hub = meta.wireguard.hub;

  # Where the clients point their resolver: the hub's tunnel addresses.
  tunnelListenAddresses = [
    (lib'.toV4 hub)
    (lib'.toV6 hub)
  ];

  # Every known VPN host under the VPN's addressing (see lib'.internalHosts),
  # so e.g. phi.internal resolves to all of phi's tunnel addresses.
  internalHostsFile = pkgs.writeText "vpn-dns-internal-hosts" lib'.internalHosts;

  # The zone for our public domain goes to the local Knot DNS server instance or,
  # on hosts that aren't authoritative, redirect to the public IP addresses of the
  # authoritative servers.
  domainUpstreams =
    if config.services.knot.enable then
      [ "/${meta.domain}/127.0.0.1#${toString cfg.knotPort}" ]
    else
      lib.concatMap (host: [
        "/${meta.domain}/${meta.perHost.${host}.publicIP.v4}"
        "/${meta.domain}/${meta.perHost.${host}.publicIP.v6}"
      ]) meta.authoritative;
in
{
  options.services.vpn-dns = {
    enable = lib.mkEnableOption ''
      the Wireguard VPN's DNS server (a split-horizon dnsmasq resolver
      on the hub, serving the VPN clients on the tunnel addresses and
      the hub host itself on localhost)
    '';

    knotPort = lib.mkOption {
      type = lib.types.port;
      default = 5354;
      description = ''
        Port the local knotd listens on when services.knot is enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = thisHost == hub;
        message = "services.vpn-dns: only the hub (meta.wireguard.hub = ${hub}) can run the VPN's DNS server; ${thisHost} is not the hub.";
      }
    ];

    services.dnsmasq = {
      enable = true;

      # Upstreams are explicit below; openresolv owns resolv.conf
      # (useLocalResolver). no-resolv keeps dnsmasq from reading
      # /etc/resolv.conf, which would loop back into this instance.
      resolveLocalQueries = false;

      settings = lib'.dnsmasqCommonSettings // {
        listen-address = [
          "127.0.0.1"
          "::1"
        ]
        ++ tunnelListenAddresses;

        no-resolv = true;

        local = [ "/${meta.internalDomain}/" ];
        addn-hosts = toString internalHostsFile;

        server = config.networking.nameservers ++ domainUpstreams;
      };
    };

    # Prepends localhost to whatever else is learned, so
    # glibc always asks dnsmasq first; public DNS servers
    # remain in resolv.conf as failure fallback only.
    networking.resolvconf.useLocalResolver = true;

    systemd.services.dnsmasq = {
      # NOTE: dnsmasq keeps CAP_NET_BIND_SERVICE after privdrop
      # and requests the dbus interface before privdrop, so there
      # is no issue with the defaults
      wantedBy = [ "network-online.target" ];
      before = [ "network-online.target" ];
    };

    # Alternative port listener on localhost for knotd.
    #
    # vd. hosts/lambda/knot.nix @ services.knot.settings.server
    services.knot.settings.server.listen = lib.mkIf config.services.knot.enable [
      "127.0.0.1@${toString cfg.knotPort}"
      "::1@${toString cfg.knotPort}"
    ];
  };
}
