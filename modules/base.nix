# Common setttings shared by every host

{
  lib,
  pkgs,
  inputs,
  meta,
  config,
  ...
}:

let
  hostName = config.networking.hostName;

  # NOTE: Authorized keys for the main user (goll) on each host: the keys every
  # other host uses to reach this one (`meta.perHost.<other>.ssh.<thisHost>`)
  authorizedKeys = lib.concatMap (
    other:
    let
      key = (meta.perHost.${other}.ssh or { }).${hostName} or "";
    in
    lib.optional (key != "") key
  ) (lib.filter (host: host != hostName) meta.allHosts);
in

{
  time.timeZone = "America/Sao_Paulo";

  networking.domain = meta.domain;
  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];

  nix.registry.nixpkgs = {
    from = {
      type = "indirect";
      id = "nixpkgs";
    };

    to = {
      type = "github";

      owner = "NixOS";
      repo = "nixpkgs";

      rev = inputs.nixpkgs.rev;
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";

    MANROFFOPT = "-c";
    MANPAGER = "${pkgs.less}/bin/less -M -R -i --use-color -Dd+R -Du+B";
  };

  environment.systemPackages = [
    pkgs.bpftrace
    pkgs.curl
    pkgs.e2fsprogs
    pkgs.fd
    pkgs.file
    pkgs.git
    pkgs.helix
    pkgs.htop
    pkgs.mtr
    pkgs.nixd
    pkgs.nixfmt
    pkgs.ripgrep
    pkgs.strace
    pkgs.tree
    pkgs.waypipe
    pkgs.wireguard-tools

    pkgs.age
    pkgs.sops

    pkgs.man-pages
    pkgs.man-pages-posix
  ];

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      UsePAM = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";

      # NOTE: Needed by some programs, such as dircolors, that won't
      # recognize some terminal emulators (e.g. foot) just from $TERM
      AcceptEnv = [ "COLORTERM" ];
    };
  };

  programs.zsh.enable = true;

  # For zsh autocompletion
  environment.pathsToLink = [ "/share/zsh" ];

  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";
  sops.defaultSopsFile = inputs.nixos-secrets.lib.secrets.perHost.${hostName};

  sops.secrets =
    let
      sharedSecret = {
        sopsFile = inputs.nixos-secrets.lib.secrets.shared;
      };
    in
    {
      "shared-secret" = sharedSecret // { };
    };

  users.mutableUsers = false;

  users.users.goll = {
    isNormalUser = true;
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = authorizedKeys;

    extraGroups = [ "wheel" ];
  };

  # Remove this after ensuring that an up-to-date version of ca-certificates is being used
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];
}
