{
  lib,
  lib',
  config,
  meta,
  pkgs,
  ...
}:

let
  cfg = config.services.local-dns;
  thisHost = config.networking.hostName;

  vpnIds = lib.attrNames meta.wireguard;

  # VPNs this host acts as hub for (star topology: the VPN key is the hub host id).
  # On a host with a merged local DNS server, these hubs are folded into this instance.
  mergedHubs = lib.optionals cfg.mergeVpnDns (lib.filter (id: thisHost == id) vpnIds);

  tunnelListenAddresses = lib.concatMap (id: [
    (lib'.toV4 id id)
    (lib'.toV6 id id)
  ]) mergedHubs;

  # Every known host under every VPN's addressing (see lib'.internalHosts),
  # so e.g. phi.internal resolves to all of phi's tunnel addresses regardless
  # of which VPN the client is on.
  internalHostsFile = pkgs.writeText "local-dns-internal-hosts" lib'.internalHosts;

  # When a hub is folded in, queries under the internal domain are answered locally;
  # otherwise forward to the tunnel dnsmasq of each VPN (hub tunnel addresses).
  internalUpstreams = lib.optionals (mergedHubs == [ ]) (
    lib.concatMap (id: [
      "/${meta.internalDomain}/${lib'.toV4 id id}"
      "/${meta.internalDomain}/${lib'.toV6 id id}"
    ]) vpnIds
  );

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
  options.services.local-dns = {
    enable = lib.mkEnableOption ''
      a local split-horizon DNS resolver (dnsmasq on 127.0.0.1/::1)
      forwarding internal domain queries to the VPN hubs and public
      domain queries to the authoritative nameservers
    '';

    mergeVpnDns = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether this host's local resolver also serves the VPNs it
        hubs directly instead of forwarding internal domain queries
        to the tunnel dnsmasq instances.
      '';
    };

    knotPort = lib.mkOption {
      type = lib.types.port;
      default = 5354;
      description = ''
        Port the local knotd listens on when services.knot is enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;

      # Upstreams are explicit below; openresolv owns resolv.conf
      # (useLocalResolver). no-resolv keeps dnsmasq from reading
      # /etc/resolv.conf, which would loop back into this instance.
      resolveLocalQueries = false;

      settings =
        lib'.dnsmasqCommonSettings
        // {
          listen-address = [
            "127.0.0.1"
            "::1"
          ]
          ++ tunnelListenAddresses;

          no-resolv = true;

          server = config.networking.nameservers ++ domainUpstreams ++ internalUpstreams;
        }
        // lib.optionalAttrs (mergedHubs != [ ]) {
          local = [ "/${meta.internalDomain}/" ];
          addn-hosts = toString internalHostsFile;
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
