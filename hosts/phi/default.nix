{
  lib',
  config,
  inputs,
  meta,
  pkgs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.default

    ./disko.nix
    ./hardware.nix
    ./desktop.nix
    ./packages.nix

    ../../modules/base.nix
    ../../modules/avatar.nix
    ../../modules/ipup.nix
    ../../modules/wireguard-vpn.nix

    ../../modules/nfs-server.nix
  ];

  nixpkgs.overlays = [ inputs.nix-firefox-addons.overlays.default ];

  sops.secrets = {
    "passwords/goll" = {
      neededForUsers = true;
    };
    "ipup-tsig-key" = {
      owner = "ipup";
    };
    "wg-key" = { };
  };

  networking.hostName = "phi";

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openconnect ];
  };

  networking.modemmanager.enable = false;

  services.openssh.openFirewall = true;

  services.ipup = lib'.mkIpupSettings {
    inherit (config.networking) hostName;

    interface = "wlp0s20f3";
    ttl = "200s";
    secret = config.sops.secrets."ipup-tsig-key".path;
  };

  services.wireguard-vpn.backend = "networkmanager";

  services.local-dns = {
    enable = true;
  };

  services.orca.enable = false;
  services.speechd.enable = false;
  services.pipewire.enable = true;

  users.users.goll = {
    # NOTE: Added to i2c group so we can control brightness of external monitors using DDC
    extraGroups = [ "i2c" ];
    hashedPasswordFile = config.sops.secrets."passwords/goll".path;
  };

  users.avatars.goll = ../../assets/pfp/image.jpg;

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [
    "pt_BR.UTF-8/UTF-8"
    "C.UTF-8/UTF-8"
  ];

  console.earlySetup = true;
  console.useXkbConfig = true;
  console.font = "Lat2-Terminus16";

  services.xserver = {
    xkb.layout = "br";
    xkb.variant = "abnt";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs meta; };
    users.goll = ./home;
  };

  system.stateVersion = "26.11";
}
