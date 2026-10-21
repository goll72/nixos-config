{ ... }:

{
  disko.devices.disk = {
    main = {
      device = "/dev/disk/by-id/scsi-3600f673a5e5d48019460db5795b3b273";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          bios = {
            size = "1M";
            type = "EF02";
          };
          swap = {
            size = "2G";
            type = "8200";
            content = {
              type = "swap";
            };
          };
          root = {
            size = "100%";
            type = "8304";
            content = {
              type = "btrfs";
              mountpoint = "/";
              mountOptions = [ "compress=zstd:5" ];
            };
          };
        };
      };
    };
  };
}
