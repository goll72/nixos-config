{ ... }:

{
  services.immich = {
    enable = true;

    host = "localhost";
    port = 2283;
    
    mediaLocation = "/tank/immich";
    
    accelerationDevices = null;
  };

  services.redis.servers.immich.logLevel = "warning";

  users.users.immich = {
    isSystemUser = true;

    group = "immich";
    extraGroups = [ "video" "render" ];
  };

  users.groups.immich = {};

  systemd.services.immich-server = {
    requires = [ "tank.mount" ];
    after = [ "tank.mount" ];
  };
}
