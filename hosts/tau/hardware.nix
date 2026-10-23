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
}
