{
  lib,
  pkgs,
  meta,
  inputs,
  config,
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
    # XXX: set up ipup to run as a non-root user
    ../../modules/ipup.nix

    ../../modules/wireguard-vpn.nix
  ];

  nixpkgs.overlays = [ inputs.nix-firefox-addons.overlays.default ];

  sops.secrets = {
    "passwords/goll" = {
      neededForUsers = true;
    };
    "ipup-tsig-key" = { };
    "wg-key" = { };
  };

  networking.hostName = "phi";

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openconnect ];
  };

  networking.modemmanager.enable = false;

  services.openssh.openFirewall = true;

  services.ipup = {
    enable = true;

    servers."${meta.domain}" = {
      fqdn = meta.domain;
      keyName = "phi.${meta.domain}";
      keyFile = config.sops.secrets."ipup-tsig-key".path;
    };

    interfaces."wlp0s20f3" = {
      server = meta.domain;
      zone = meta.domain;
      record = "phi";

      ttl = "200s";

      deleteExisting = true;
    };
  };

  services.wireguard-vpn = {
    phi = {
      name = "phi.net";
      interface = "wg.phi";
      backend = "networkmanager";
      privateKeySecret = "wg-key";
    };

    lambda = {
      name = "lambda.net";
      interface = "wg.lambda";
      backend = "networkmanager";
      privateKeySecret = "wg-key";
    };
  };

  # Start a local DNS server that will forward requests under the internal
  # domain to the VPN-specific DNS servers, requests specific to our public
  # domain to one of the authoritative nameservers and other requests to
  # select public DNS servers. More importantly, this setup still allows
  # other VPNs and private networks to extend the resolver list in
  # resolv.conf via DHCP.
  services.local-dns = {
    enable = true;
    # If the DNS server for the phi.net VPN and the local proxy were merged, we would
    # have to list entries for the VPN's DNS in resolv.conf, adding uncertainty as to
    # which nameservers are tried first for resolution of any given name.
    mergeVpnDns = false;
  };

  services.orca.enable = false;
  services.speechd.enable = false;
  services.pipewire.enable = true;

  users.users.goll = {
    extraGroups = [ "i2c" ];
    hashedPasswordFile = config.sops.secrets."passwords/goll".path;
  };

  users.avatars.goll = ../../assets/pfp/image.jpg;

  environment.binsh = lib.getExe pkgs.dash;

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
