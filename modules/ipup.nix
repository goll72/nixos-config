{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.services.ipup;
  ini = pkgs.formats.ini { };

  serverSections = lib.mapAttrs' (
    name: srv:
    lib.nameValuePair "server/${name}" (
      {
        fqdn = srv.fqdn;
        port = srv.port;
        key-name = srv.keyName;
        key-file = srv.keyFile;
        key-algo = srv.keyAlgo;
        max-retry = srv.maxRetry;
      }
      // lib.optionalAttrs (srv.zone != null) { zone = srv.zone; }
      // lib.optionalAttrs (srv.record != null) { record = srv.record; }
    )
  ) cfg.servers;

  ifaceSections = lib.mapAttrs' (
    name: iface:
    lib.nameValuePair "iface/${name}" (
      {
        server = iface.server;
      }
      // lib.optionalAttrs (iface.zone != null) { zone = iface.zone; }
      // lib.optionalAttrs (iface.record != null) { record = iface.record; }
      // lib.optionalAttrs (iface.ttl != null) { ttl = iface.ttl; }
      // lib.optionalAttrs iface.respectTTL { respect-ttl = iface.respectTTL; }
      // lib.optionalAttrs iface.deleteExisting { delete-existing = iface.deleteExisting; }
    )
  ) cfg.interfaces;
in
{
  options.services.ipup = {
    enable = lib.mkEnableOption "ipup, an RFC 2136 dynamic DNS updater";

    package = lib.mkPackageOption pkgs "ipup" { };

    servers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            fqdn = lib.mkOption {
              type = lib.types.str;
              description = "FQDN of the DNS server to send updates to.";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 53;
              description = "Port used for the DNS connection.";
            };

            keyName = lib.mkOption {
              type = lib.types.str;
              description = "Name of the TSIG key used to authenticate updates.";
            };

            keyFile = lib.mkOption {
              type = lib.types.path;
              description = ''
                Path to a file containing only the Base64-encoded TSIG key
                secret. Point this at a sops-nix secret to keep the key out
                of the Nix store, e.g.
                `config.sops.secrets."ipup/tsig".path`.
              '';
            };

            keyAlgo = lib.mkOption {
              type = lib.types.str;
              default = "HMAC-SHA512";
              description = ''
                TSIG key algorithm. Possible values can be listed with
                `ldns-keygen -a list`.
              '';
            };

            maxRetry = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 10;
              description = "Maximum number of retries before giving up on an update.";
            };

            zone = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                DNS zone for records updated through this server. May be set
                here or on each interface, but not on both for the same pair.
              '';
            };

            record = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                DNS record updated through this server. May be set here or on
                each interface, but not on both for the same pair.
              '';
            };
          };
        }
      );
      default = { };
      description = "DNS servers keyed by name, referenced from interfaces.";
    };

    interfaces = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            server = lib.mkOption {
              type = lib.types.str;
              description = "Name of a server in `services.ipup.servers`.";
            };

            zone = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "DNS zone for this interface's records (or set it on the server).";
            };

            record = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "DNS record for this interface (or set it on the server).";
            };

            ttl = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "86400s";
              description = ''
                TTL for the records, a duration such as "86400s" or "1d".
                Defaults to 1 hour when unset. Mutually exclusive with
                `respectTTL`.
              '';
            };

            respectTTL = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Match the TTL of the DNS record to the address' valid
                lifetime. Only enable this if leases are consistently short.
                Mutually exclusive with `ttl`.
              '';
            };

            deleteExisting = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Delete DNS records not present in the kernel address table on startup.";
            };
          };
        }
      );
      default = { };
      description = "Network interfaces to watch, keyed by interface name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.concatMap (
      ifaceName:
      let
        iface = cfg.interfaces.${ifaceName};
        srv = cfg.servers.${iface.server} or null;
      in
      [
        {
          assertion = srv != null;
          message = "services.ipup.interfaces.${ifaceName}.server references unknown server '${iface.server}'";
        }
        {
          assertion = !(iface.ttl != null && iface.respectTTL);
          message = "services.ipup.interfaces.${ifaceName}: ttl and respectTTL are mutually exclusive";
        }
        {
          assertion = !(iface.zone != null && srv != null && srv.zone != null);
          message = "services.ipup.interfaces.${ifaceName}.zone conflicts with zone set on server '${iface.server}'";
        }
        {
          assertion = !(iface.record != null && srv != null && srv.record != null);
          message = "services.ipup.interfaces.${ifaceName}.record conflicts with record set on server '${iface.server}'";
        }
        {
          assertion =
            (iface.zone != null || (srv != null && srv.zone != null))
            && (iface.record != null || (srv != null && srv.record != null));
          message = "services.ipup.interfaces.${ifaceName}: zone and record must be set on the interface or on server '${iface.server}'";
        }
      ]
    ) (lib.attrNames cfg.interfaces);

    users.groups.ipup = { };

    users.users.ipup = {
      isSystemUser = true;
      group = "ipup";
    };

    environment.etc."ipup/conf".source = ini.generate "ipup.conf" (serverSections // ifaceSections);

    # For manual oneshot runs (ipup -o).
    environment.systemPackages = [ cfg.package ];

    systemd.services.ipup = {
      description = "ipup dynamic DNS updater";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "ipup";
        Group = "ipup";

        # -s logs to stdout, which journald picks up when running unprivileged.
        ExecStart = "${lib.getExe cfg.package} -c /etc/ipup/conf -s";
        Restart = "on-failure";
        RestartSec = 10;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        # ipup watches addresses through netlink; DNS needs inet sockets.
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
      };
    };
  };
}
