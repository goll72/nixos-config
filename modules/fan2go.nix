{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.services.fan2go;

  fan2goConfigFile = cfg.configFile or "/etc/fan2go/fan2go.yaml";

  configText = lib.optionalString (!lib.isNull cfg.config) (pkgs.formats.yaml cfg.config);
in
{
  options.services.fan2go = {
    enable = lib.mkEnableOption "fan2go hardware fan control daemon";

    package = lib.mkPackageOption pkgs "fan2go" { };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/fan2go/fan2go.yaml";
      description = "Path to the fan2go YAML configuration file.";
    };

    config = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Direct translation of the fan2go YAML configuration.
      '';
    };

    noStyle = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pass --no-style to fan2go (disable ANSI escape codes).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."fan2go/fan2go.yaml".text = configText;

    systemd.services.fan2go = {
      description = "fan2go hardware fan control daemon";
      documentation = "https://github.com/markusressel/fan2go";

      after = [ "lm-sensors.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart =
          lib.concatStringsSep " " [
            (lib.getExe pkgs.fan2go)
            "-c"
            fan2goConfigFile
          ]
          ++ (lib.optionalString "--no-style");

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";

        PrivateDevices = false;

        DeviceAllow = [
          "/dev/null rw"
          "/dev/zero rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia0 rw"
          "/dev/nvidia1 rw"
          "/dev/nvidia2 rw"
          "/dev/nvidia3 rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-uvm-tools rw"
          "/dev/nvidia-caps/* r"
          "/dev/urandom r"
          "char-hwmon rw"
          "char-thermal rw"
          "char-i2c rw"
          "char-misc rw"
          "block-sd r"
          "block-blkext r"
        ];

        ReadWritePaths = [
          "/sys/class/hwmon"
          "/sys/class/thermal"
          "/sys/devices"
        ];

        ReadOnlyPaths = [
          "/sys/bus"
          "/proc/cpuinfo"
          "/proc/meminfo"
          "-/etc/sensors3.conf"
          "-/etc/sensors.conf"
          "/proc/modules"
          "/sys/module"
        ];

        PrivateNetwork = false;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        IPAddressDeny = "any";
        IPAddressAllow = [
          "localhost"
          "127.0.0.0/8"
          "::1/128"
        ];

        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;

        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;

        PrivateUsers = false;
        ProtectHostname = true;
        ProtectClock = true;

        CapabilityBoundingSet = [
          "CAP_DAC_OVERRIDE"
          "CAP_FOWNER"
          "CAP_SYS_RAWIO"
          "CAP_CHOWN"
        ];
        AmbientCapabilities = [ "CAP_SYS_RAWIO" ];

        SystemCallFilter = [
          "@system-service"
          "~@debug"
          "@mount"
          "@cpu-emulation"
          "@obsolete"
          "@privileged"
          "@reboot"
          "@swap"
          "@resources"
          "@raw-io"
        ];
        SystemCallErrorNumber = "EPERM";

        MemoryMax = "256M";
        TasksMax = 50;
        LimitNOFILE = 1024;
      };
    };
  };
}
