{
  lib',
  config,
  inputs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops

    ./disko.nix
    ./hardware.nix
    ./packages.nix

    ../../roles/base.nix
    ../../modules/avatar.nix
    ../../modules/ipup.nix
    ../../modules/vpn/wireguard.nix
    ../../modules/vpn/nfs.nix
  ];

  sops.secrets = {
    "passwords/goll" = {
      neededForUsers = true;
    };
    "ipup-tsig-key" = {
      owner = "ipup";
    };
    "wg-key" = { };
  };

  networking.hostName = "tau";

  networking.networkmanager.enable = true;
  networking.modemmanager.enable = false;

  services.ipup = lib'.mkIpupSettings {
    inherit (config.networking) hostName;

    interface = "enp6s0";
    ttl = "300s";
    secret = config.sops.secrets."ipup-tsig-key".path;
  };

  services.vpn = {
    wireguard.enable = true;
    nfs.enable = true;
  };

  services.local-dns.enable = true;

  users.users.goll.hashedPasswordFile = config.sops.secrets."passwords/goll".path;

  system.stateVersion = "26.11";
}
