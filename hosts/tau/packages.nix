{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.llama-cpp
    pkgs.nvtopPackages.amd
  ];
}
