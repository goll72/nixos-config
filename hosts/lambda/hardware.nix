{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # With IPv6 forwarding on, the kernel ignores router advertisements at
  # accept_ra=1, which would expire enp0s3's RA-provided default route.
  boot.kernel.sysctl."net.ipv6.conf.enp0s3.accept_ra" = 2;

  networking.dhcpcd.IPv6rs = false;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_scsi"
    "usbhid"
    "sd_mod"
  ];
}
