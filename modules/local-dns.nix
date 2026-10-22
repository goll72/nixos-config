# Local DNS resolver (dnsmasq) for every VPN host: guarantees that
# queries under the internal domain go to the VPN's DNS server —
# answered directly on the hub, forwarded to the hub from elsewhere —
# while queries for our public domain go to the local knotd (or, on
# hosts that aren't authoritative, to the public IPs of the
# authoritative servers) and everything else to select public DNS
# servers.
#
# On the hub it also owns the tunnel addresses, where the other VPN
# clients point their resolver. In all cases it doubles as the host's
# own resolver: localhost is prepended to resolv.conf via openresolv
# (useLocalResolver), so glibc always asks dnsmasq first.

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

  hub = meta.wireguard.hub;
  isHub = thisHost == hub;

  # The tunnel addresses of the hub: the VPN's DNS server.
  hubAddresses = [
    (lib'.toV4 hub)
    (lib'.toV6 hub)
  ];

  # Away from the hub, internal queries are forwarded to the hub's
  # resolver; on the hub they are answered locally (see below).
  internalUpstreams = lib.optionals (!isHub) (
    map (addr: "/${meta.internalDomain}/${addr}") hubAddresses
  );

  # Every known VPN host under the VPN's addressing (see lib'.internalHosts).
  internalHostsFile = pkgs.writeText "local-dns-internal-hosts" lib'.internalHosts;

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
      a local split-horizon DNS resolver (dnsmasq on 127.0.0.1/::1),
      guaranteeing that internal domain queries reach the VPN's DNS
      server (answered locally on the hub, forwarded to it elsewhere)
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
        assertion = config.networking.resolvconf.enable;
        message = "services.local-dns: resolv.conf is fed via resolvconf; set networking.resolvconf.enable = true.";
      }
    ];

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
          ++ lib.optionals isHub hubAddresses;

          no-resolv = true;

          server = config.networking.nameservers ++ domainUpstreams ++ internalUpstreams;
        }
        // lib.optionalAttrs isHub {
          local = [ "/${meta.internalDomain}/" ];
          addn-hosts = toString internalHostsFile;
        };
    };

    # Prepends localhost to whatever else is learned, so
    # glibc always asks dnsmasq first; public DNS servers
    # remain in resolv.conf as failure fallback only.
    networking.resolvconf.useLocalResolver = true;

    # The VPN's search domain; the VPN modules themselves carry no
    # DNS settings anymore.
    networking.search = [ meta.internalDomain ];

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
