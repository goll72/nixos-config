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

    ../../roles/base.nix
    ../../roles/server.nix
    ../../modules/vpn/wireguard.nix
    ../../modules/vpn/nfs.nix
  ];

  sops.secrets."wg-key" = { };

  networking.hostName = "mu";

  services.vpn.nfs.enable = true;

  # Key-only SSH auth (no passwords on this host)
  users.users.goll = { };

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };

  system.stateVersion = "25.11";
}
