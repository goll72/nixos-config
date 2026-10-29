# Shared helper functions, passed to every host via `specialArgs.lib'`

{ lib, meta }:

rec {
  # Every known VPN host under the VPN's addressing, so e.g.
  # phi.internal resolves to all of phi's tunnel addresses (v4 and v6).
  #
  # NOTE: Every VPN host gets a ULA domain, but obviously
  # hosts can be assigned ULAs without being part of the VPN.
  internalHosts = lib.concatMapStrings (host: ''
    ${toV4 "wireguard" host} ${host}.${meta.internalDomain}
    ${toV6 "wireguard" host} ${host}.${meta.internalDomain}
    ${toV6 "local" host} ula.${host}.${meta.internalDomain}
  '') meta.vpnHosts;

  # Functions used to convert host names to their VPN addresses
  toV4 = net: host: "${meta.${net}.v4.prefix}${lib.toString meta.perHost.${host}.id}";
  toV6 = net: host: "${meta.${net}.v6.prefix}${lib.toHexString meta.perHost.${host}.id}";

  # Settings for the dnsmasq instances of services.local-dns.
  dnsmasqCommonSettings = {
    all-servers = true;
    bind-dynamic = true;
    dns-loop-detect = true;
    local-ttl = 300;
  };

  mkIpupSettings =
    {
      interface,
      hostName,
      ttl,
      secret,
    }:
    {
      enable = true;

      servers."${meta.domain}" = {
        fqdn = meta.domain;
        keyName = "${hostName}.${meta.domain}";
        keyFile = secret;
      };

      interfaces."${interface}" = {
        server = meta.domain;
        zone = meta.domain;
        record = hostName;

        inherit ttl;

        deleteExisting = true;
      };
    };
}
