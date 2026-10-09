
{ lib, pkgs, config, ... }:

let
  cfg = config.services.hydroxide;
in {
  options.services.hydroxide = {
    enable = lib.mkEnableOption "Hydroxide (Protonmail bridge) service";

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Domain for the TLS certificate (used to find the certificate path automatically if ACME is enabled)";
    };

    cert = lib.mkOption {
      type = lib.types.str;
      description = "Path to the X.509 certificate file used by Hydroxide";
    };

    key = lib.mkOption {
      type = lib.types.str;
      description = "Path to the X.509 private key file used by Hydroxide";
    };

    useACME = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use ACME-generated certificates (adds `hydroxide` to `acme` group)";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      description = "Environment file (define `HYDROXIDE_BRIDGE_PASS` here)";
    };
  };

  config = let
    acmeDir = "/var/lib/acme";

    cert = if cfg.domain == null then cfg.cert else "${acmeDir}/${cfg.domain}/fullchain.pem";
    key = if cfg.domain == null then cfg.key else "${acmeDir}/${cfg.domain}/key.pem";
  in
  lib.mkIf cfg.enable {
    users.groups.hydroxide = {};

    users.users.hydroxide = {
      isSystemUser = true;
      group = "hydroxide";
      extraGroups = lib.mkIf cfg.useACME [ "acme" ];

      home = "/var/lib/hydroxide";
      createHome = true;
    };
    
    systemd.services.hydroxide = {
      wants = [ "network.target" ];
      after = [ "network.target" ];
      
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        User = "hydroxide";
        ExecStart = "${pkgs.hydroxide}/bin/hydroxide -tls-cert ${cert} -tls-key ${key} -smtp-host [::] -smtp-port 465 -imap-host [::] -imap-port 993 -disable-carddav serve";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        
        EnvironmentFile = cfg.environmentFile;
      };

      environment = {
        # Hydroxide will use `auth.json` from `$XDG_CONFIG_HOME/hydroxide` -> `/var/lib/hydroxide`
        XDG_CONFIG_HOME = "/var/lib";
      };
    };
  };
}
