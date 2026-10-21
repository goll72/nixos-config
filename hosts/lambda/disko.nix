{ ... }:

{
  disko.devices.disk = {
    main = {
      device = "/dev/disk/by-id/scsi-36016d0240aaf45c7b11380d05944b869";
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
              mountOptions = [ "compress=zstd:5" ];
              swap.swapfile = {
                size = "4G";
                path = "/var/swap";
              };
            };
          };
        };
      };
    };
  };
}
