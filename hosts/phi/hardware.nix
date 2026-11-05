{
  pkgs,
  ...
}:

let
  linux = pkgs.linuxPackages_latest;

  linux-hda-codec-conexant = pkgs.callPackage ../../packages/linux/hda-codec-conexant {
    inherit (linux) kernel;
  };
in
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

  boot.kernelModules = [ "acer_charger_mute" ];

  boot.extraModulePackages = [
    pkgs.acer-charger-mute

    (linux-hda-codec-conexant.overrideAttrs (_: {
      patches = [
        # Adds a hardware quirk for the Acer Aspire Go 15 so
        # the LED on the microphone mute key works properly.
        ./patches/linux/acer-micmute-led.patch
      ];
    }))
  ];

  # XXX: Workaround for nixpkgs packaging oversight after systemd v262 update,
  # now requiring the systemd-pcrextend socket to be enabled for PCR extension
  # in the initrd to work properly
  #
  # Remove once https://github.com/NixOS/nixpkgs/pull/581067 is merged
  boot.initrd.systemd.sockets.systemd-pcrextend.wantedBy = [ "sockets.target" ];

  boot.kernelPackages = linux;

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

  # Workaround for the keyboard exposing the microphone mute
  # key as F15 rather than the proper `micmute` scancode
  services.udev.extraHwdb = ''
    evdev:input:b0018v1025p174Be0100*
      KEYBOARD_KEY_7006a=micmute
  '';
}
