{
  lib,
  lib',
  config,
  meta,
  pkgs,
  ...
}:

let
  cfg = config.services.wireguard-vpn;

  # One-directional read of literal local-dns options (no module cycle:
  # local-dns derives everything from meta). When set, the local resolver
  # takes over .internal for the hubs this host serves, so the per-VPN
  # dnsmasq instances are redundant. "Standalone" means the local
  # resolver runs here but does not fold the hubs in (e.g. phi), so
  # NetworkManager must point connections at 127.0.0.1 instead of the
  # hub tunnel addresses.
  localDnsMerged = config.services.local-dns.enable && config.services.local-dns.mergeVpnDns;
  localDnsStandalone = config.services.local-dns.enable && !config.services.local-dns.mergeVpnDns;
in
{
  imports = [
    # local-dns and knot-zone-watch are independent leaf modules; this
    # module is the only one that imports both (it reads the former's
    # options and configures the latter's rules).
    ./local-dns.nix
    ./knot-zone-watch.nix
  ];

  options.services.wireguard-vpn = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Human-readable name for this VPN.";
          };

          interface = lib.mkOption {
            type = lib.types.str;
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

              The `networkmanager` backend uses NetworkManager to manage the Wireguard interface and DNS
              (uses `services.networkmanager.ensureProfiles.profiles.<name>` internally)
            '';
          };

          privateKeySecret = lib.mkOption {
            type = lib.types.str;
            description = ''
              Name of the sops secret containing this host's Wireguard private key.
              The same keypair is reused across all VPNs this host participates in.
            '';
          };
        };
      }
    );

    default = { };
  };

  config =
    let
      # One list of plain config fragments per VPN. Fragments are merged
      # with mkMerge semantics below (so e.g. `listOf` options concatenate
      # instead of replace, as a recursiveUpdate of the fragments would).
      snippets = lib.mapAttrsToList (
        id:
        {
          name,
          interface,
          backend,
          privateKeySecret,
        }:
        let
          thisHost = config.networking.hostName;

          subnets = meta.wireguard.${id};

          getIPsForHost = x: [
            "${lib'.toV4 id x}/32"
            "${lib'.toV6 id x}/128"
          ];

          getIPsForNet = x: [
            "${subnets.v4.prefix}0/${lib.toString subnets.v4.len}"
            "${subnets.v6.prefix}0/${lib.toString subnets.v6.len}"
          ];

          snippetForBackend = {
            networkmanager =
              let
                # NOTE: This hash is used to prevent environment variable
                # clashes if multiple Wireguard VPNs are defined using NM
                nameHash = builtins.hashString "sha256" name;

                clientPeers = map (x: {
                  "wireguard-peer.${meta.perHost.${x}.wireguard}" = {
                    allowed-ips = lib.concatStringsSep ";" (getIPsForHost x);
                  };
                }) (lib.lists.filter (x: x != id) meta.vpnHosts);

                serverOptions = {
                  wireguard = {
                    listen-port = meta.wireguard.${id}.port;
                    private-key = "$WG_${nameHash}_PRIVATE_KEY";
                    private-key-flags = 0;
                  };
                }
                // lib.mergeAttrsList clientPeers;

                clientOptions = {
                  wireguard = {
                    private-key = "$WG_${nameHash}_PRIVATE_KEY";
                    private-key-flags = 0;
                  };

                  "wireguard-peer.${meta.perHost.${id}.wireguard}" = {
                    allowed-ips = lib.concatStringsSep ";" (getIPsForNet id);
                    endpoint = "${id}.${meta.domain}:${lib.toString meta.wireguard.${id}.port}";
                  };
                };
              in
              {
                sops.templates."wireguard-vpn-${nameHash}-env".content = ''
                  WG_${nameHash}_PRIVATE_KEY=${config.sops.placeholder.${privateKeySecret}}
                '';

                networking.networkmanager = {
                  enable = true;

                  ensureProfiles = {
                    environmentFiles = [
                      config.sops.templates."wireguard-vpn-${nameHash}-env".path
                    ];

                    profiles.${name} = {
                      connection = {
                        id = name;
                        type = "wireguard";
                        interface-name = interface;
                        autoconnect = false;
                      };

                      ipv4 = {
                        address1 = "${lib'.toV4 id thisHost}/${lib.toString subnets.v4.len}";
                        method = "manual";

                        dns = if localDnsStandalone then "127.0.0.1" else lib'.toV4 id id;
                        dns-search = meta.internalDomain;
                      }
                      // lib.optionalAttrs localDnsStandalone {
                        # Ahead of the uplink connection's DHCP DNS so
                        # glibc asks the local resolver first.
                        dns-priority = -1;
                      };

                      ipv6 = {
                        address1 = "${lib'.toV6 id thisHost}/${lib.toString subnets.v6.len}";
                        method = "manual";

                        dns-search = meta.internalDomain;
                      }
                      // lib.optionalAttrs (!localDnsStandalone) { dns = lib'.toV6 id id; };
                    }
                    // (lib.optionalAttrs (thisHost == id) serverOptions)
                    // (lib.optionalAttrs (thisHost != id) clientOptions);
                  };
                };
              };

            wireguard =
              let
                resolvconfRecord = ''
                  nameserver ${lib'.toV4 id id}
                  nameserver ${lib'.toV6 id id}
                  search ${meta.internalDomain}
                '';

                serverOptions = {
                  privateKeyFile = config.sops.secrets.${privateKeySecret}.path;

                  ips = [
                    "${lib'.toV4 id id}/${lib.toString subnets.v4.len}"
                    "${lib'.toV6 id id}/${lib.toString subnets.v6.len}"
                  ];

                  peers = map (x: {
                    name = x;
                    publicKey = meta.perHost.${x}.wireguard;
                    allowedIPs = getIPsForHost x;
                  }) (lib.lists.filter (x: x != id) meta.vpnHosts);

                  listenPort = meta.wireguard.${id}.port;
                };

                clientOptions = {
                  privateKeyFile = config.sops.secrets.${privateKeySecret}.path;

                  ips = getIPsForHost thisHost;

                  peers = [
                    {
                      name = id;
                      publicKey = meta.perHost.${id}.wireguard;
                      allowedIPs = getIPsForNet id;
                      endpoint = "${id}.${meta.domain}:${lib.toString meta.wireguard.${id}.port}";
                    }
                  ];
                };
              in
              {
                assertions = [
                  {
                    assertion = config.networking.resolvconf.enable;
                    message = ''
                      services.wireguard-vpn.${id}: the wireguard backend registers VPN DNS via resolvconf;
                      set networking.resolvconf.enable = true (and do not let another service manage /etc/resolv.conf).
                    '';
                  }
                ];

                networking.wireguard = {
                  enable = true;

                  interfaces.${interface} = {
                    # The wireguard backend does not manage DNS, so feed the
                    # VPN's DNS server to resolvconf ourselves. This is what
                    # the upstream NixOS wireguard module recommends.
                    postSetup = ''
                      printf '%s' ${lib.escapeShellArg resolvconfRecord} \
                        | ${config.networking.resolvconf.package}/bin/resolvconf -a ${interface} -m 0
                    '';

                    postShutdown = ''
                      ${config.networking.resolvconf.package}/bin/resolvconf -d ${interface}
                    '';
                  }
                  // lib.optionalAttrs (thisHost == id) serverOptions
                  // lib.optionalAttrs (thisHost != id) clientOptions;
                };
              };
          };

          dnsServerSection =
            let
              # All hosts under every VPN's addressing (aligned with
              # local-dns), so a name resolves wherever the client is.
              dnsmasqHostsFile = pkgs.writeText "hosts" lib'.internalHosts;

              dnsmasqConfigFile = (lib'.dnsmasqSettingsFormat pkgs).generate "dnsmasq-${id}.conf" (
                lib'.dnsmasqCommonSettings
                // {
                  no-hosts = true;
                  addn-hosts = toString dnsmasqHostsFile;
                  listen-address = "${lib'.toV4 id thisHost},${lib'.toV6 id thisHost}";
                }
              );
            in
            {
              systemd.services."wireguard-vpn-${id}-dns-server" = {
                enable = true;
                description = "DNS server for Wireguard VPN ${name}";

                serviceConfig = {
                  ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq -k -C ${dnsmasqConfigFile}";
                };
              }
              // (
                if backend == "wireguard" then
                  {
                    wantedBy = [ "wireguard-${interface}.service" ];
                    after = [ "wireguard-${interface}.service" ];
                  }
                else
                  {
                    wantedBy = [ "network.target" ];
                  }
              );
            };

          firewallSection = {
            networking.firewall.allowedUDPPorts = [ meta.wireguard.${id}.port ];
            networking.firewall.checkReversePath = "loose";

            # XXX: extend this later
            networking.firewall.interfaces.${interface} = {
              allowedUDPPorts = [ 53 ];
              allowedTCPPorts = [ 53 ];
            };
          };
        in
        [
          snippetForBackend.${backend}
        ]
        ++ lib.optional (thisHost == id && !localDnsMerged) dnsServerSection
        ++ lib.optional (thisHost == id) firewallSection
      ) cfg;

      fragments = lib.concatLists snippets;
    in
    {
      # NOTE: The top-level config (and the `networking` subtree) must be attrsets with
      # statically known keys: if their structure depended on `cfg` (e.g. a mkMerge over
      # mapAttrsToList), collecting config structure would force `cfg`, whose fragments
      # read `config.networking.hostName`, leading to  infinite recursion.
      #
      # Thus, the cfg-dependent merges live one level down, under
      # the fixed keys below; fragments may only touch those keys.
      assertions = lib.mkMerge (map (fragment: fragment.assertions or [ ]) fragments);

      # Refresh this host's WireGuard peer when a dynamic hub re-registers
      # its address: the zone watcher clears dnsmasq's cache and restarts
      # the peer unit, whose wg set resolves the endpoint afresh.
      services.knot-zone-watch.rules = lib.concatMap (
        id:
        let
          thisHost = config.networking.hostName;
          inherit (cfg.${id}) backend interface;
        in
        lib.optional (backend == "wireguard" && thisHost != id && lib.elem id meta.dynamicHosts) {
          name = "${id}.${meta.domain}.";
          zone = "${meta.domain}.";
          rrtypes = [ "AAAA" ];
          units = [ "wireguard-${interface}-peer-${id}.service" ];
        }
      ) (lib.attrNames cfg);

      sops.templates = lib.mkMerge (map (fragment: fragment.sops.templates or { }) fragments);

      networking = {
        networkmanager = lib.mkMerge (map (fragment: fragment.networking.networkmanager or { }) fragments);
        wireguard = lib.mkMerge (map (fragment: fragment.networking.wireguard or { }) fragments);
        firewall = lib.mkMerge (map (fragment: fragment.networking.firewall or { }) fragments);
      };

      systemd.services = lib.mkMerge (map (fragment: fragment.systemd.services or { }) fragments);
    };
}
