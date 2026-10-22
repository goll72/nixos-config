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

  # XXX:
  # # The hub forwards IPv6 (wireguard-vpn); with forwarding on, the kernel
  # # ignores router advertisements at accept_ra=1, which would expire
  # # enp0s3's RA-provided default route — and thus the WireGuard endpoints
  # # reachable only over v6.
  # boot.kernel.sysctl."net.ipv6.conf.enp0s3.accept_ra" = 2;

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

    openssh.authorizedKeys.keys = meta.perHost.lambda.extraUsers.xhcl.keys;
  };

  system.stateVersion = "25.11";
}
