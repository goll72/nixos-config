{ config, meta, ... }:

let
  navidrome = config.services.navidrome;
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
        };
      in
      {
        "mu.${meta.domain}" = {
          enableACME = true;
          locations."/".proxyPass =
            "http://${navidrome.settings.Address}:${toString navidrome.settings.Port}";
        }
        // common;
      };
  };
}
