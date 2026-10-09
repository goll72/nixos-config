{ pkgs, ... }:

{
  security.tpm2.enable = true;
  systemd.tpm2.enable = true;
  systemd.tpm2.pcrphases.enable = true;

  boot.zswap.enable = true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "vmd"
    "nvme"
    "sd_mod"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";

    autoGenerateKeys.enable = true;

    autoEnrollKeys = {
      enable = true;
      # NOTE: No impact for this machine, no valid option
      # ROMs were found under /sys or in the TPM event log
      includeMicrosoftKeys = false;
      allowBrickingMyMachine = true;
    };
  };

  # NOTE: Lanzaboote currently replaces the systemd-boot module
  # (it uses systemd-boot internally)
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics = {
    enable = true;
    extraPackages = [
      pkgs.intel-media-driver
      pkgs.vpl-gpu-rt
    ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
