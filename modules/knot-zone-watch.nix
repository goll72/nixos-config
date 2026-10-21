# Sets up a systemd service to listen for zone updates from the Knot DNS server
# and automatically restart Wireguard peer units to update the information about
# endpoints whose IP addresses have changed.

{
  lib,
  config,
  options,
  pkgs,
  ...
}:

let
  cfg = config.services.knot-zone-watch;

  knot = config.services.knot.package;

  # The watcher queries the localhost knotd listener on the port chosen by
  # services.local-dns (which also asserts it is enabled below). Read the
  # option without importing local-dns.nix so this module stays a leaf.
  knotPort = if options.services ? local-dns then config.services.local-dns.knotPort else 5354;

  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.dbus-python
    ps.pygobject3
  ]);

  rulesFile = pkgs.writeText "knot-zone-watch-rules.json" (builtins.toJSON cfg.rules);

  # The shipped dnsmasq D-Bus policy only lets *root* send to
  # uk.org.thekelleys.dnsmasq, and base system.conf denies method_call
  # anyway — without this hole the watcher's ClearCache call would be
  # rejected and it would fall back to restarting dnsmasq on every zone
  # update.
  dnsmasqPolicy = pkgs.writeTextDir "share/dbus-1/system.d/knot-zone-watch.conf" ''
    <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
     "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
    <busconfig>
      <policy user="knot-zone-watch">
        <allow send_destination="uk.org.thekelleys.dnsmasq"/>
      </policy>
    </busconfig>
  '';

  watcherScript = pkgs.writeText "knot-zone-watch.py" (
    builtins.replaceStrings
      [
        "@KDIG@"
        "@SYSTEMCTL@"
        "@BASH@"
        "@KNOT_PORT@"
        "@RULES_FILE@"
      ]
      [
        (lib.getExe' knot "kdig")
        "${config.systemd.package}/bin/systemctl"
        (lib.getExe pkgs.bash)
        (toString knotPort)
        (toString rulesFile)
      ]
      (builtins.readFile ./knot-zone-watch.py)
  );
in
{
  options.services.knot-zone-watch = {
    enable = lib.mkEnableOption "restarting WireGuard peer units when Knot reports zone updates";

    rules = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Fully qualified name of the record to watch, e.g. \"phi.goll.cc.\".";
            };

            zone = lib.mkOption {
              type = lib.types.str;
              description = "Knot zone whose updates trigger the check, e.g. \"goll.cc.\".";
            };

            rrtypes = lib.mkOption {
              type = lib.types.listOf (
                lib.types.enum [
                  "A"
                  "AAAA"
                ]
              );
              default = [ "AAAA" ];
              description = "Record types included in the fingerprint.";
            };

            units = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "systemd units restarted when the watched record changes.";
            };

            commands = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                Shell commands run (as the watcher user, after the cache
                flush and any unit restarts) when the watched record
                changes. For non-systemd restarts, e.g. nmcli connection
                up <profile>; such commands need their own polkit
                permissions.
              '';
            };
          };
        }
      );
      default = [ ];
      description = "Watched records and the units restarted on change.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.knot.enable;
        message = "services.knot-zone-watch requires services.knot.enable (zone_updated signals).";
      }
      {
        assertion = options.services ? local-dns && config.services.local-dns.enable;
        message = "services.knot-zone-watch requires services.local-dns (imported and enabled): it owns the 127.0.0.1 listener used for fresh authoritative queries.";
      }
    ];

    services.knot.settings.server.dbus-event = "zone-updated";

    # The D-Bus policy for knotd owning its name ships with the
    # dbus-enabled knot-dns package (overlays/knot-dns-dbus.nix).
    # knot-dns is multi-output; the policy lives in `out` (string
    # coercion would resolve to the `bin` output).
    services.dbus.packages = [
      knot.out
      dnsmasqPolicy
    ];

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "knot-zone-watch") {
          var unit = action.lookup("unit");
          if (unit && (unit.match(/^wireguard-.+-peer-.+\.service$/) ||
                       unit == "dnsmasq.service")) {
            return polkit.Result.YES;
          }
        }
        return polkit.Result.NOT_HANDLED;
      });
    '';

    users.groups.knot-zone-watch = { };

    users.users.knot-zone-watch = {
      isSystemUser = true;
      group = "knot-zone-watch";
      description = "Knot zone watcher (WireGuard endpoint refresh)";
    };

    systemd.services.knot-zone-watch = {
      description = "Restart WireGuard peers on Knot zone updates";
      wantedBy = [ "multi-user.target" ];
      after = [
        "dbus.service"
        "knot.service"
        "dnsmasq.service"
      ];

      serviceConfig = {
        ExecStart = "${pythonEnv}/bin/python ${watcherScript}";
        User = "knot-zone-watch";
        StateDirectory = "knot-zone-watch";
        Restart = "on-failure";
        RestartSec = 5;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
      };
    };
  };
}
