{
  lib,
  lib',
  config,
  meta,
  ...
}:

let
  cfg = config.services.wireguard-vpn;
in
{
  imports = [
    # local-dns is an independent leaf module; this module is the only
    # one that imports it (its hosts are exactly the VPN hosts).
    ./local-dns.nix
  ];

  options.services.wireguard-vpn = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "${meta.wireguard.hub}.net";
      description = "Human-readable name for this VPN.";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Name of the interface used for this VPN.";
    };

    backend = lib.mkOption {
      type = lib.types.enum [
        "wireguard"
        "networkmanager"
      ];

      description = ''
        Backend used for setting up the network.

        The `wireguard` backend uses plain `wg` commands in systemd services
        (uses `services.wireguard.<interface>` internally)

        The `networkmanager` backend uses NetworkManager to manage the Wireguard interface
        (uses `services.networkmanager.ensureProfiles.profiles.<name>` internally)
      '';
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
  # through `config.services.wireguard-vpn`. The mkIf gates defer the
  # cfg-dependent structure to value forcing, when cfg is resolvable.
  config =
    let
      inherit (cfg)
        name
        interface
        backend
        privateKeySecret
        ;

      thisHost = config.networking.hostName;
      hub = meta.wireguard.hub;
      isHub = thisHost == hub;
      isNM = backend == "networkmanager";
      isWG = backend == "wireguard";

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

      nmServerOptions = {
        wireguard = {
          listen-port = meta.wireguard.port;
          private-key = "$WG_PRIVATE_KEY";
          private-key-flags = 0;
        };
      }
      // lib.mergeAttrsList (
        map (x: {
          "wireguard-peer.${meta.perHost.${x}.wireguard}" = {
            allowed-ips = lib.concatStringsSep ";" (getIPsForHost x);
          };
        }) otherHosts
      );

      nmClientOptions = {
        wireguard = {
          private-key = "$WG_PRIVATE_KEY";
          private-key-flags = 0;
        };

        "wireguard-peer.${meta.perHost.${hub}.wireguard}" = {
          allowed-ips = lib.concatStringsSep ";" vpnNet;
          endpoint = "${hub}.${meta.domain}:${lib.toString meta.wireguard.port}";
          # Keep the client-side NAT mapping alive so the session survives
          # idle periods and either end can renegotiate.
          persistent-keepalive = 25;
        };
      };

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
            # Keep the client-side NAT mapping alive so the session survives
            # idle periods and either end can renegotiate.
            persistentKeepalive = 25;
          }
        ];
      };
    in
    {
      sops.templates = lib.mkIf isNM {
        "wireguard-vpn-env".content = ''
          WG_PRIVATE_KEY=${config.sops.placeholder.${privateKeySecret}}
        '';
      };

      networking.networkmanager = lib.mkIf isNM {
        enable = true;

        ensureProfiles = {
          environmentFiles = [
            config.sops.templates."wireguard-vpn-env".path
          ];

          profiles.${name} = {
            connection = {
              id = name;
              type = "wireguard";
              interface-name = interface;
              autoconnect = false;
            };

            ipv4 = {
              address1 = "${lib'.toV4 thisHost}/${lib.toString subnets.v4.len}";
              method = "manual";

              dns-search = [ meta.internalDomain ];
            };

            ipv6 = {
              address1 = "${lib'.toV6 thisHost}/${lib.toString subnets.v6.len}";
              method = "manual";

              dns-search = [ meta.internalDomain ];
            };
          }
          // (if isHub then nmServerOptions else nmClientOptions);
        };
      };

      networking.wireguard = lib.mkIf isWG {
        enable = true;

        interfaces.${interface} = if isHub then wgServerOptions else wgClientOptions;
      };

      networking.search = lib.mkIf isWG [ meta.internalDomain ];

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
    };
}
