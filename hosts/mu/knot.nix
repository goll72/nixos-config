{ lib', meta, ... }:

let
  lambda = lib'.toV4 "lambda";
  mu = lib'.toV4 "mu";
in
{
  services.knot = {
    enable = true;

    settings = {
      server = {
        # Public service on port 53; port 54 serves the Wireguard
        # VPN address (zone transfers to/peers with lambda ride
        # that one). The localhost alternative port used by local
        # clients is added in services.local-dns.
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
