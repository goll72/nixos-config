# Placeholder host — not yet configured.
{ ... }:

{
  imports = [ ./hardware.nix ];

  networking.hostName = "tau";

  system.stateVersion = "26.11";
}
