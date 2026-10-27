{ ... }:

{
  disko.devices.disk = {
    main = {
      device = "/dev/disk/by-id/wwn-0x5f8db4c40190de56";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              mountpoint = "/";
              mountOptions = [ "compress=zstd:9" ];
              swap.swapfile = {
                size = "4G";
                path = "/var/swap";
              };
            };
          };
        };
      };
    };
    tank = {
      device = "/dev/disk/by-id/wwn-0x50014ee2ba7558f6";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          unit = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              mountpoint = "/tank";
              mountOptions = [ "nofail" "compress=zstd:5" ];
            };
          };
        };
      };
    };
  };
}
