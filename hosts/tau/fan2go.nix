{ lib, config }:

{
  environment.systemPackages = [
    config.services.fan2go.package
  ];

  services.fan2go = {
    enable = true;

    config = {
      fans = [
        {
          id = "cpu";

          hwmon = {
            platform = "k10temp-pci-00c3";
            rpmChannel = 1;
            pwmChannel = 1;
          };

          neverStop = true;
          curve = "cpu";
        }
        {
          id = "gpu";

          hwmon = {
            platform = "amdgpu-pci-0100";
            rpmChannel = 1;
            pwmChannel = 1;
          };

          neverStop = true;
          curve = "gpu";
        }
      ];

      curves =
        let
          p = temperature: percentage: { ${lib.toString temperature} = percentage; };
        in
        [
          {
            id = "cpu";
            linear = {
              sensor = "temp1_input";

              steps = [
                (p 30 "0%")
                (p 40 "10%")
                (p 50 "30%")
                (p 60 "70%")
                (p 75 "100%")
              ];
            };
          }
          {
            id = "gpu";
            linear = {
              sensor = "temp1_input";

              steps = [
                (p 30 "0%")
                (p 40 "30%")
                (p 50 "70%")
                (p 60 "100%")
              ];
            };
          }
        ];
    };
  };
}
