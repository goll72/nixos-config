{ meta, ... }:

let
  lambda = meta.toV4 "lambda" "lambda";
  mu = meta.toV4 "lambda" "mu";
in
{
  services.knot = {
    enable = true;

    settings = {
      server = {
        listen = [
          "127.0.0.1@53"
          "::1@53"
          "${meta.perHost.mu.privateIP.v4}@53"
          "${meta.perHost.mu.publicIP.v6}@53"
          "${mu}@54"
        ];

        automatic-acl = true;
      };

      remote.lambda.address = "${lambda}@54";

      template.default = {
        # Zonefileless, like the primary: the transferred
        # (signed) zone lives entirely in the journal.
        zonefile-sync = -1;
        zonefile-load = "none";
        journal-content = "all";
      };

      zone.${meta.domain}.master = "lambda";
    };
  };
}
