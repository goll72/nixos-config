{ ... }:

{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_scsi"
    "usbhid"
    "sd_mod"
  ];
}
