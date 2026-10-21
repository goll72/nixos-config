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
        # The localhost alternative port is added in services.local-dns.
        #
        # vd. hosts/lambda/knot.nix @ services.knot.settings.server
        listen = [
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
