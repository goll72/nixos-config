{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops

    ./disko.nix
    ./hardware.nix
    ./packages.nix

    ./acme.nix
    ./knot.nix
    ./navidrome.nix
    ./nginx.nix

    ../../modules/base.nix
    ../../modules/server.nix
    ../../modules/wireguard-vpn.nix
  ];

  sops.secrets."wg-key" = { };

  networking.hostName = "mu";

  # Key-only SSH auth (no passwords on this host)
  users.users.goll = { };

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };

  system.stateVersion = "25.11";
}
