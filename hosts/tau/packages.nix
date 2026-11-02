{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.llama-cpp-vulkan
    pkgs.amdtop
    pkgs.amdgpu_top
  ];
}
