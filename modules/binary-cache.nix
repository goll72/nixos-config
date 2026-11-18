{
  lib,
  lib',
  meta,
  config,
  ...
}:

let
  # The set of hosts that serve as binary caches, keyed by their
  # system architecture. A host serves as a cache for every other
  # host sharing the same system.
  cacheHostsBySystem = lib.listToAttrs (
    lib.map (host: {
      name = host;
      value = meta.perHost.${host}.system;
    }) meta.vpnHosts
  );

  # Hosts that share a system with at least one other host (i.e. hosts
  # that are actually useful as a cache for someone else).
  cacheHostsForSystem = system: lib.filter (host: cacheHostsBySystem.${host} == system) meta.vpnHosts;

  # The VPN address (v4) this host binds the binary cache to.
  bindAddress = lib'.toV4 "wireguard" config.networking.hostName;

  thisHost = config.networking.hostName;
  thisSystem = meta.perHost.${thisHost}.system;

  port = meta.binaryCache.port;

  # Other hosts on the VPN that share this system and thus can
  # serve as a binary cache for us.
  otherCacheHosts = lib.filter (x: x != thisHost) (cacheHostsForSystem thisSystem);

  # The substituter URL for a given cache host.
  substituterFor = host: "http://${host}.${meta.internalDomain}:${toString port}";
  publicKeyFor = host: meta.binaryCache.publicKeys.${host};

  serverConfig = lib.mkIf config.services.vpn.binaryCache.serve {
    services.harmonia.cache = {
      enable = true;
      signKeyPaths = [ config.sops.secrets."harmonia-key".path ];
      settings = {
        # Bind to the VPN address directly so the cache is only
        # reachable over the Wireguard tunnel (HTTP only, no TLS).
        bind = "${bindAddress}:${toString port}";
        priority = meta.binaryCache.priority;
      };
    };

    sops.secrets."harmonia-key" = { };

    # Ensure the socket is created only after the VPN is up so
    # binding to the VPN address succeeds.
    systemd.sockets.harmonia = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    networking.firewall.interfaces.${config.services.vpn.wireguard.interface}.allowedTCPPorts = [
      port
    ];
  };

  clientConfig = lib.mkIf (config.services.vpn.binaryCache.pull && otherCacheHosts != [ ]) {
    nix.settings = {
      substituters = map substituterFor otherCacheHosts;
      trusted-public-keys = map publicKeyFor otherCacheHosts;
    };
  };

  mergedConfig = lib.mkMerge [
    serverConfig
    clientConfig
  ];
in
{
  options.services.vpn.binaryCache = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether this host should participate in the Wireguard binary
        cache mesh. When enabled, this host may serve as a harmonia
        server for other hosts sharing the same system, and/or pull
        from such caches when one is available.
      '';
    };

    serve = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to run the harmonia server on this host. When enabled,
        this host serves as a binary cache for all other hosts with
        the same system.
      '';
    };

    pull = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to configure nix substituters to pull from other
        binary caches on the VPN that share this host's system.
      '';
    };
  };

  config = lib.mkIf config.services.vpn.binaryCache.enable mergedConfig;
}
