{
  meta,
  config,
  ...
}:

{
  sops.templates."acme-env".content = ''
    RFC2136_NAMESERVER=127.0.0.1
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
