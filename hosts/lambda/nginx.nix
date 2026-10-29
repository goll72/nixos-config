{
  lib,
  config,
  meta,
  ...
}:

let
  cfg = config.services.vaultwarden.config;

  # Upstream for the vault vhost. services.vaultwarden.config's declared
  # ROCKET_* defaults only apply when the option has no definitions at all;
  # hosts/lambda/vaultwarden.nix sets other keys, so fall back to
  # vaultwarden's own runtime defaults (rocket: any interface, port 8000).
  bind = cfg.ROCKET_ADDRESS or "0.0.0.0";
  port = cfg.ROCKET_PORT or 8000;

  # Wildcard binds are not a connectable target; a listener on any interface
  # is reachable on loopback. IPv6 literals need bracketing in URLs.
  upstreamHost =
    {
      "0.0.0.0" = "127.0.0.1";
      "::" = "[::1]";
      "[::]" = "[::1]";
    }
    .${bind} or (if builtins.match ".*:.*" bind != null then "[${bind}]" else bind);

  vaultwardenUpstream = "http://${upstreamHost}:${lib.toString port}";
in
{
  services.nginx = {
    enable = true;
    group = "acme";

    virtualHosts =
      let
        common = {
          useACMEHost = meta.domain;
          http2 = true;
          forceSSL = true;
        };
      in
      {
        "vault.${meta.domain}" = {
          locations."/".proxyPass = vaultwardenUpstream;
        }
        // common;

        ${meta.domain} = {
          locations."/" = {
            root = "/srv/www/webroot";
            tryFiles = "$uri $uri/index.html $uri.html =404";
          };

          extraConfig = ''
            gzip on;
            etag on;
            rewrite ^(.+)/$ $1 permanent;

            add_header Cache-Control "no-cache" always;
          '';
        }
        // common;
      };
  };
}
