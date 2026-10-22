# NFSv4 file sharing over the WireGuard VPN
#
# This module implements automounts for NFS peers and bind mounts a
# directory containing each automount dir to a slave bind of each
# host's export directory, that way a single directory tree can keep
# all the exports of all hosts in an easily accessible way.

{
  lib,
  config,
  meta,
  pkgs,
  ...
}:

let
  cfg = config.services.vpn.nfs;
  wg = config.services.vpn.wireguard;

  thisHost = config.networking.hostName;
  otherHosts = lib.lists.filter (x: x != thisHost) meta.vpnHosts;

  runPath = "/run/nfs";

  exportImportPath = "${cfg.exportPath}/${cfg.importSubdir}";
  localImportPath = "${cfg.localPath}/${cfg.importSubdir}";

  sh = lib.escapeShellArg;
in
{
  options.services.vpn.nfs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to export this host's export path to the other VPN hosts
        and mount their exports under the import subdir.
      '';
    };

    exportPath = lib.mkOption {
      type = lib.types.str;
      default = "/srv/nfs";
      description = "Directory exported to the other VPN hosts.";
    };

    localPath = lib.mkOption {
      type = lib.types.str;
      default = "/data";
      description = "Local view of the export path, set up as a bind mount of the export path.";
    };

    importSubdir = lib.mkOption {
      type = lib.types.str;
      default = "@";
      description = ''
        Name of the import subdirectory: kept as an empty immutable
        placeholder inside the export path, while below the local view it
        shows the peers' exports.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.vpn.wireguard.enable;
        message = "services.vpn.nfs exports over and firewall-opens the WireGuard interface; set services.vpn.wireguard.enable";
      }
      {
        assertion = cfg.exportPath != cfg.localPath;
        message = "services.vpn.nfs.localPath must not equal exportPath";
      }
      {
        assertion =
          !lib.hasPrefix "${cfg.exportPath}/" cfg.localPath
          && !lib.hasPrefix "${cfg.localPath}/" cfg.exportPath;
        message = "services.vpn.nfs.localPath and exportPath must not be nested";
      }
      {
        assertion = cfg.importSubdir != "" && !(lib.hasInfix "/" cfg.importSubdir);
        message = "services.vpn.nfs.importSubdir must be a single directory name";
      }
    ];

    # Guarantees the paths exist and adds the immutable attribute to the import
    # subdir to avoid other files/directories from ending up there.
    system.activationScripts.vpn-nfs-dirs.text = ''
      mkdir -p ${
        lib.concatMapStringsSep " " sh [
          cfg.exportPath
          exportImportPath
          cfg.localPath
          localImportPath
          runPath
        ]
      }
      ${lib.getExe' pkgs.e2fsprogs "chattr"} +i ${sh exportImportPath} 2>/dev/null \
        || warn "could not make ${exportImportPath} immutable"
    '';

    services.nfs = {
      server = {
        enable = true;
        hostName = "${thisHost}.${meta.internalDomain}";

        exports.${cfg.exportPath} = lib.attrsets.mergeAttrsList (
          map (x: {
            "${x}.${meta.internalDomain}" = [
              "fsid=0"
              "rw"
              "insecure"
              "crossmnt"
            ];
          }) meta.vpnHosts
        );
      };

      settings = {
        nfsd = {
          nfsv3 = false;
          nfsv4 = true;
        };
      };
    };

    systemd.services = {
      rpc-statd.enable = lib.mkForce false;
      rpc-statd-notify.enable = lib.mkForce false;

      # Add a stub since NFSv4 doesn't use the MOUNT protocol, so nothing needs to run.
      # NOTE: we can't mask this service since nfs-server.service requires it.
      nfs-mountd.serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
      };

      # The wireguard interface must have been brought up before
      # nfs-server binds to it.
      nfs-server = {
        after = [ "wireguard-${wg.interface}.service" ];
        wants = [ "wireguard-${wg.interface}.service" ];
      };

      # Assemble the local view of the export. The make-slave/make-rslave
      # calls are idempotent, so re-running after a partial setup doesn't
      # pose an issue.
      #
      # The device:inode check keeps us from grafting the view onto a
      # local path that is a mount of something else entirely, rather
      # than a bind-mount of the export path.
      vpn-nfs-view = {
        description = "Local view of the VPN NFS export";
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.util-linux ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if ! mountpoint -q ${sh cfg.localPath}; then
            mount --bind ${sh cfg.exportPath} ${sh cfg.localPath}
          fi

          if [ "$(stat -c '%d:%i' ${sh cfg.localPath})" = "$(stat -c '%d:%i' ${sh cfg.exportPath})" ]; then
            mount --make-slave ${sh cfg.localPath}

            if ! mountpoint -q ${sh localImportPath}; then
              mount --rbind ${sh runPath} ${sh localImportPath}
            fi
            mount --make-rslave ${sh localImportPath}
          else
            echo "vpn-nfs: ${cfg.localPath} is not a bind of ${cfg.exportPath}, skipping the local view" >&2
          fi
        '';
      };
    };

    networking.firewall.interfaces.${wg.interface} = {
      allowedTCPPorts = [ 2049 ];
      allowedUDPPorts = [ 2049 ];
    };

    boot.supportedFilesystems.nfs = true;

    # No After=vpn-nfs-view.service here: systemd already orders every
    # automount unit before local-fs.target, so the automounts are armed
    # before the view comes up (local-fs -> sysinit -> basic -> view).
    # Adding that edge would close the chain into an ordering cycle, and
    # it isn't needed anyway: the view's rbind either copies mounts that
    # already exist or receives later ones via propagation.
    systemd.automounts = map (x: {
      where = "${runPath}/${x}";

      wantedBy = [ "multi-user.target" ];

      # Unmount after 15m if mount is unused
      automountConfig.TimeoutIdleSec = "900s";
    }) otherHosts;

    # Reduce initial mount timeout from the default of 900s to 3s to avoid hangups
    systemd.mounts = map (x: {
      what = "${x}.${meta.internalDomain}:/";
      where = "${runPath}/${x}";

      type = "nfs";
      options = "vers=4,soft";

      mountConfig.TimeoutSec = "3s";
    }) otherHosts;
  };
}
