{
  config,
  lib,
  pkgs,
  ...
}:

let
  package = pkgs.typst-bot;

  stateDir = "/var/lib/typsy";
  cacheDir = "/var/cache/typsy";
in
{
  sops.secrets.discord-typsy-token = {
    owner = "typsy";
    group = "typsy";
  };

  users.users.typsy = {
    isSystemUser = true;
    group = "typsy";
  };

  users.groups.typsy = { };

  systemd.services.typsy = {
    description = "Typst Discord Bot";

    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      User = "typsy";
      Group = "typsy";

      StateDirectory = "typsy";
      CacheDirectory = "typsy";

      WorkingDirectory = stateDir;

      ExecStart = pkgs.writeShellScript "typsy-start" ''
        export DISCORD_TOKEN="$(< ${config.sops.secrets.discord-typsy-token.path})"
        exec ${lib.getExe' package "bot"}
      '';

      Environment = [
        "DB_PATH=${stateDir}/db.sqlite"
        "CACHE_DIRECTORY=${cacheDir}"
        "TYPST_BOT_WORKER_PATH=${lib.getExe' package "worker"}"
      ];

      Restart = "on-failure";
      RestartSec = "5s";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
    };
  };
}
