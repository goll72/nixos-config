{
  lib,
  lib',
  config,
  meta,
  ...
}:

let
  cfg = config.services.vpn.wireguard;
in
{
  imports = [
    # local-dns is an independent leaf module; this module is the only
    # one that imports it (its hosts are exactly the VPN hosts).
    ../local-dns.nix
  ];

  options.services.vpn.wireguard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to bring up this host's WireGuard interface for the VPN
        (uses `networking.wireguard.<interface>` internally).
      '';
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Name of the interface used for this VPN.";
    };

    privateKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "wg-key";
      description = "Name of the sops secret containing this host's Wireguard private key.";
    };
  };

  # NOTE: The top-level config keys below must stay statically known
  # (no cfg-dependent keys, no mkMerge over cfg): collecting the config
  # structure forces them, and reading `cfg` at that point recurses
  # through `config.services.vpn.wireguard`. The mkIf gates defer the
  # cfg-dependent structure to value forcing, when cfg is resolvable.
  config = lib.mkIf cfg.enable (
    let
      inherit (cfg) interface privateKeySecret;

      thisHost = config.networking.hostName;
      hub = meta.wireguard.hub;
      isHub = thisHost == hub;

      subnets = meta.wireguard;

      getIPsForHost = x: [
        "${lib'.toV4 x}/32"
        "${lib'.toV6 x}/128"
      ];

      # The whole VPN under its v4 and v6 addressing.
      vpnNet = [
        "${subnets.v4.prefix}0/${lib.toString subnets.v4.len}"
        "${subnets.v6.prefix}0/${lib.toString subnets.v6.len}"
      ];

      otherHosts = lib.lists.filter (x: x != hub) meta.vpnHosts;

      wgServerOptions = {
        privateKeyFile = config.sops.secrets.${privateKeySecret}.path;

        ips = [
          "${lib'.toV4 hub}/${lib.toString subnets.v4.len}"
          "${lib'.toV6 hub}/${lib.toString subnets.v6.len}"
        ];

        peers = map (x: {
          name = x;
          publicKey = meta.perHost.${x}.wireguard;
          allowedIPs = getIPsForHost x;
        }) otherHosts;

        listenPort = meta.wireguard.port;
      };

      wgClientOptions = {
        privateKeyFile = config.sops.secrets.${privateKeySecret}.path;

        ips = getIPsForHost thisHost;

        peers = [
          {
            name = hub;
            publicKey = meta.perHost.${hub}.wireguard;
            allowedIPs = vpnNet;
            endpoint = "${hub}.${meta.domain}:${lib.toString meta.wireguard.port}";
            # Keep the client-side NAT mapping alive so the session
            # survives idle periods and either end can renegotiate.
            persistentKeepalive = 25;
          }
        ];
      };
    in
    {
      networking.wireguard = {
        enable = true;
        interfaces.${interface} = if isHub then wgServerOptions else wgClientOptions;
      };

      networking.search = [ meta.internalDomain ];

      # Does nothing if NetworkManager isn't being used
      networking.networkmanager.unmanaged = [ interface ];

      # In a star topology, the hub will drop packets unless IP forwarding is set
      # up or custom routing is implemented.
      #
      # (if forwarding IPv6 accept_ra=2 is also needed on their WAN; see hosts/lambda)
      boot.kernel.sysctl = lib.mkIf isHub {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      networking.firewall = lib.mkIf isHub {
        allowedUDPPorts = [ meta.wireguard.port ];
        checkReversePath = "loose";

        interfaces.${interface} = {
          allowedUDPPorts = [ 53 ];
          allowedTCPPorts = [ 53 ];
        };
      };
    }
  );
}
