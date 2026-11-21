{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:

{
  options.services.zellij-prune = {
    enable = lib.mkEnableOption "Run zellij-prune to prune old Zellij sessions periodically";

    maxAge = lib.mkOption {
      type = lib.types.str;
      default = "1w";
      description = ''
        Maximum session age before pruning. Human-readable (e.g. "2w", "30m", "1d")
        or raw seconds. Passed to zellij-prune's --max-age.
      '';
    };

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "@";
      description = ''
        Session-name prefix that marks a session as exempt (never pruned).
        Passed to zellij-prune's --prefix.
      '';
    };
  };

  config = lib.mkIf config.services.zellij-prune.enable (
    let
      pkg = inputs.zellij-prune.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      systemd.user.services.zellij-prune = {
        description = "Prune old Zellij sessions";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkg}/bin/zellij-prune --max-age ${config.services.zellij-prune.maxAge} --prefix ${config.services.zellij-prune.prefix}";
        };
      };

      systemd.user.timers.zellij-prune = {
        description = "Run zellij-prune periodically";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    }
  );
}
