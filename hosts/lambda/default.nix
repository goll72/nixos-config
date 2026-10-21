{
  lib,
  pkgs,
  meta,
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

    ./acme.nix
    ./knot.nix
    ./vaultwarden.nix
    ./nginx.nix
    ./hydroxide.nix

    ../../modules/base.nix
    ../../modules/server.nix
    ../../modules/hydroxide.nix
    ../../modules/wireguard-vpn.nix
  ];

  sops.secrets = {
    "acme-tsig-key" = { };

    "dns-ksk" = {
      owner = "knot";
    };

    "hydroxide-auth-json" = {
      owner = "hydroxide";
      path = "/var/lib/hydroxide/auth.json";
    };

    "hydroxide-bridge-pass" = { };

    "wg-key" = { };
  }
  // lib.mergeAttrsList (map (x: { "host-tsig-key/${x}" = { }; }) meta.dynamicHosts);

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # Key-only SSH auth (no password on this host)
  users.users.goll = { };

  users.users.xhcl = {
    isNormalUser = true;
    extraGroups = [ "xhcl" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFlPCfGx5D6pE13e9F4A0Mv5xKapRW1BenmFMvi89ErM xhcl@xylo"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO0O9xJpxw0OuYXmyLoSovKUgo6H9Y9Eo8eO3XV4VKaP xhcl@pixel"
    ];
  };

  system.stateVersion = "25.11";
}
