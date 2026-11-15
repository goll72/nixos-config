{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.amdtop
    pkgs.amdgpu_top
    pkgs.llama-cpp-vulkan
    pkgs.pciutils
    pkgs.usbutils
  ];
}
