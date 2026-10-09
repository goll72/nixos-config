{
  disko.devices.disk = {
    main = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "256M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "root";

              settings = {
                crypttabExtraOpts = [
                  "tpm2-device=auto"
                  "tpm2-measure-pcr=yes"
                  "fixate-volume-key=d3f215bbe783665fbadadf1ae76310e32a7314e463fad7142331ffbe1b5963b6"
                ];
                
                allowDiscards = true;
              };

              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd:9" ];
                    swap.swapfile = {
                      size = "8G";
                      path = "swap";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

