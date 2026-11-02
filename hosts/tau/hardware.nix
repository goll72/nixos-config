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

  # Workaround for instability issues in AMDGPU
  #
  # Without these kernel parameters/sysfs DPM performance level override,
  # the dGPU will frequently crash under load, often requiring a reboot.
  boot.kernelParams = [
    "amdgpu.aspm=0"
    "amdgpu.runpm=0"

    "iommu=pt"
  ];

  boot.kernel.sysfs = {
    class.drm."card[0-9]*".device.power_dpm_force_performance_level = "high";
  };

  # Prevent fan2go failing at boot due to not finding the AMDGPU hwmon device
  hardware.amdgpu.initrd.enable = true;

  hardware.graphics.enable = true;

  hardware.enableRedistributableFirmware = true;
}
