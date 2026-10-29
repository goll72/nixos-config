{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.availableKernelModules = [
    "kvm-amd"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];

  # Prevent fan2go failing at boot due to not finding the AMDGPU hwmon device
  hardware.amdgpu.initrd.enable = true;

  hardware.graphics.enable = true;

  hardware.enableRedistributableFirmware = true;
}
