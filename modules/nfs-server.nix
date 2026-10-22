# Sets up an NFS server (NFSv4 only)

{
  lib,
  config,
  meta,
  pkgs,
  ...
}:

let
  thisHost = config.networking.hostName;
in
{
  services.nfs = {
    server = {
      enable = true;
      hostName = "${thisHost}.${meta.internalDomain}";

      exports."/data" = lib.attrsets.mergeAttrsList (
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
  };

  networking.firewall.interfaces."wg0".allowedTCPPorts = [ 2049 ];
}
