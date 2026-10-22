{
  config,
  meta,
  ...
}:

{
  # The RFC2136 client targets the local knotd on the port owned by the vpn-dns module.
  assertions = [
    {
      assertion = config.services.vpn-dns.enable;
      message = "RFC2136_NAMESERVER uses services.vpn-dns.knotPort; enable services.vpn-dns.";
    }
  ];

  sops.templates."acme-env".content = ''
    RFC2136_NAMESERVER=127.0.0.1:${toString config.services.vpn-dns.knotPort}
    RFC2136_TSIG_KEY=acme
    RFC2136_TSIG_ALGORITHM=hmac-sha512.
    RFC2136_TSIG_SECRET=${config.sops.placeholder."acme-tsig-key"}
  '';

  security.acme = {
    acceptTerms = true;
    defaults.email = meta.email;

    certs.${meta.domain} = {
      extraDomainNames = [
        "*.${meta.domain}"
      ];

      dnsProvider = "rfc2136";
      dnsPropagationCheck = false;

      environmentFile = config.sops.templates."acme-env".path;
    };
  };
}
