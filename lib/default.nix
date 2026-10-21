# Shared helper functions, passed to every host via `specialArgs.lib'`

{ lib, meta }:

rec {
  # Every known host under every VPN's addressing, so e.g. phi.internal
  # resolves to all of phi's tunnel addresses regardless of which VPN
  # the client is on.
  #
  # This guarantees that a service (e.g. NFS) running on one VPN won't
  # be denied for hosts making requests from another VPN.
  internalHosts = lib.concatMapStrings (
    host:
    lib.concatMapStrings (id: ''
      ${toV4 id host} ${host}.${meta.internalDomain}
      ${toV6 id host} ${host}.${meta.internalDomain}
    '') (lib.attrNames meta.wireguard)
  ) meta.vpnHosts;

  # Functions used to convert host names to their VPN addresses inside a given VPN
  toV4 = subnet: host: "${meta.wireguard.${subnet}.v4.prefix}${lib.toString meta.perHost.${host}.id}";
  toV6 =
    subnet: host: "${meta.wireguard.${subnet}.v6.prefix}${lib.toHexString meta.perHost.${host}.id}";

  # Settings shared by every dnsmasq instance: the split-horizon resolver
  # from services.local-dns and the per-VPN tunnel DNS servers.
  dnsmasqCommonSettings = {
    bind-dynamic = true;
    dns-loop-detect = true;
    local-ttl = 300;
  };

  # Key/value renderer with the same boolean semantics as
  # services.dnsmasq.settings (bare flag for `true`), for dnsmasq
  # instances not managed by the NixOS dnsmasq module.
  dnsmasqSettingsFormat =
    pkgs:
    pkgs.formats.keyValue {
      mkKeyValue =
        name: value:
        if value == true then
          name
        else if value == false then
          "# ${name} explicitly set to false"
        else
          lib.generators.mkKeyValueDefault { } "=" name value;

      listsAsDuplicateKeys = true;
    };

  # services.wireguard-vpn definitions for the star-topology VPNs defined in meta.wireguard
  wireguardVpnPeers =
    backend:
    lib.mapAttrs (id: _: {
      name = "${id}.net";
      interface = "wg.${id}";
      inherit backend;
      privateKeySecret = "wg-key";
    }) meta.wireguard;
}
