{
  lib,
  inputs,
  meta,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops

    ./disko.nix
    ./hardware.nix
    ./packages.nix

    ./acme.nix
    ./hydroxide.nix
    ./knot.nix
    ./nginx.nix
    ./vaultwarden.nix

    ../../modules/base.nix
    ../../modules/server.nix
    ../../modules/hydroxide.nix
    ../../modules/vpn-dns.nix
    ../../modules/wireguard-vpn.nix
  ];

  sops.secrets = {
    "acme-tsig-key" = { };

    "dns-ksk" = {
      owner = "knot";
    };

    "hydroxide-bridge-pass" = { };

    "wg-key" = { };
  }
  // lib.mergeAttrsList (map (x: { "host-tsig-key/${x}" = { }; }) meta.dynamicHosts);

  boot.binfmt = {
    emulatedSystems = [ "x86_64-linux" ];
    preferStaticEmulators = true;
  };

  # NOTE: this is a temporary fix for https://github.com/NixOS/nixpkgs/issues/366902
  nixpkgs.overlays = [
    (final: prev: {
      qemu-user = prev.qemu-user.overrideAttrs (old: {
        configureFlags = old.configureFlags ++ [ "--disable-pie" ];
      });
    })
  ];

  networking.hostName = "lambda";

  # The DNS server for the Wireguard VPN; also lambda's own local resolver.
  services.vpn-dns.enable = true;

  # Key-only SSH auth (no password on this host)
  users.users.goll = { };

  users.users.xhcl = {
    isNormalUser = true;
    extraGroups = [ "xhcl" ];

    openssh.authorizedKeys.keys = meta.perHost.lambda.extraUsers.xhcl.keys;
  };

  system.stateVersion = "25.11";
}
