{
  meta,
  ...
}:

{
  services.nginx = {
    enable = true;
    group = "acme";

    virtualHosts = let
      common = {
        useACMEHost = meta.domain;
        http2 = true;
        forceSSL = true;
      };
    in {
      "vault.${meta.domain}" = {
        locations."/".proxyPass = "http://127.0.0.1:8000";
      } // common;

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
    } // common;
    };
  };
}
