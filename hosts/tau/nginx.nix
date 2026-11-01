{
  lib,
  config,
  meta,
  ...
}:

let
  immich = config.services.immich;
in
{
  services.nginx = {
    enable = true;
    group = "acme";

    virtualHosts =
      let
        common = {
          http2 = true;
          forceSSL = true;

          enableACME = true;
        };
      in
      {
        "tau.${meta.domain}" = {
          root = "/var/empty";
        }
        // common;

        "media.${meta.domain}" = {
          locations."/" = {
            proxyPass = "http://${immich.host}:${lib.toString immich.port}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
            extraConfig = ''
              client_max_body_size 50000M;
              proxy_read_timeout 600s;
              proxy_send_timeout 600s;
              send_timeout 600s;
            '';
          };
        }
        // common;
      };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
