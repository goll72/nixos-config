{ pkgs, ... }:

{
  boot.loader.grub.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "kvm-amd"
    "xhci_pci"
    "virtio_blk"
    "virtio_iommu"
    "virtio_mmio"
    "virtio_pci"
    "virtio_scsi"
    "uhci_hcd"
    "usbhid"
    "sd_mod"
  ];
}
