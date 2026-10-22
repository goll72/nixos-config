# NFSv4 file sharing over the WireGuard VPN: this host exports a path for
# its peers and mounts every peer's export under its import subdir.
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

  importPath = x: "${cfg.exportPath}/${cfg.importSubdir}/${x}";
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
      default = "/data";
      description = "Directory exported to the other VPN hosts.";
    };

    importSubdir = lib.mkOption {
      type = lib.types.str;
      default = "@";
      description = "Subdirectory of the export path where the other hosts' exports are mounted.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Populate the export path and the import subdir up front; the automount
    # units would create the latter anyway, but exportfs needs the former
    # when nfs-server starts.
    systemd.tmpfiles.rules = [
      "d ${cfg.exportPath} 0755 - - -"
      "d ${cfg.exportPath}/${cfg.importSubdir} 0755 - - -"
    ];

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
    }
    # The wireguard backend must have brought the interface up before
    # nfs-server binds to it. When using the NetworkManager backend, the
    # NFS server only gets started when actually connected to the VPN,
    # via an nm-dispatcher script (below).
    // lib.optionalAttrs (wg.backend == "wireguard") {
      nfs-server = {
        after = [ "wireguard-${wg.interface}.service" ];
        wants = [ "wireguard-${wg.interface}.service" ];
      };
    }
    // lib.optionalAttrs (wg.backend == "networkmanager") {
      nfs-server.wantedBy = lib.mkForce [ ];
    };

    networking.firewall.interfaces."${wg.interface}" = {
      allowedTCPPorts = [ 2049 ];
      allowedUDPPorts = [ 2049 ];
    };

    # NetworkManager invokes dispatcher scripts with the interface name as
    # $1 and the action as $2 (see nm-dispatcher(8)).
    networking.networkmanager.dispatcherScripts = lib.mkIf (wg.backend == "networkmanager") [
      {
        type = "basic";
        source = pkgs.writeShellScript "nfs-server-vpn" ''
          if [ "$1" != "${wg.interface}" ]; then
            exit 0
          fi

          case "$2" in
            up)
              exec ${pkgs.systemd}/bin/systemctl start nfs-server.service
              ;;
            down)
              exec ${pkgs.systemd}/bin/systemctl stop nfs-server.service
              ;;
          esac
        '';
      }
    ];

    # Client side: each peer's export uses fsid=0, so the export root
    # serves as the mount root. Automounts keep the mounts lazy and only
    # bring nfs-server (on the peer) traffic when a path is accessed.
    boot.supportedFilesystems.nfs = true;

    systemd.automounts = map (x: {
      where = importPath x;
      wantedBy = [ "multi-user.target" ];
    }) otherHosts;

    systemd.mounts = map (x: {
      what = "${x}.${meta.internalDomain}:/";
      where = importPath x;
      type = "nfs";
      options = "vers=4";
    }) otherHosts;
  };
}
