# Common settings shared by every host

{
  lib,
  config,
  inputs,
  meta,
  pkgs,
  ...
}:

let
  inherit (config.networking) hostName;

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

  boot.tmp.cleanOnBoot = true;

  networking.domain = meta.domain;
  networking.search = lib.mkAfter [ meta.domain ];

  # Remove the 127.0.0.2 entries for the local hostname
  networking.hosts."127.0.0.2" = lib.mkForce [ ];

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
    pkgs.knot-dns
    pkgs.mtr
    pkgs.ncdu
    pkgs.nixd
    pkgs.nixfmt
    pkgs.ripgrep
    pkgs.strace
    pkgs.tree
    pkgs.waypipe
    pkgs.wireguard-tools
    pkgs.zellij

    pkgs.age
    pkgs.sops

    pkgs.man-pages
    pkgs.man-pages-posix
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;

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

  programs.ssh = {
    agentTimeout = "30m";

    extraConfig = ''
      VisualHostKey yes
      SendEnv COLORTERM
    '';
  };

  programs.zsh = {
    enable = true;

    interactiveShellInit = ''
      autoload -Uz add-zsh-hook

      set_term_title() {
        print -Pn '\e]0;%m:%1~%(!. (#).)\a'
      }

      add-zsh-hook precmd set_term_title

      REPORTTIME=10

      setopt HIST_IGNORE_SPACE
    '';

    promptInit = ''
      setopt PROMPT_SUBST
      PROMPT='%m:%4~ %# '
    '';
  };

  environment.binsh = "${pkgs.dash}/bin/dash";

  # For zsh autocompletion
  environment.pathsToLink = [ "/share/zsh" ];

  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";
  sops.defaultSopsFile = inputs.nixos-secrets.lib.secrets.perHost.${hostName};

  sops.secrets =
    let
      shared = {
        sopsFile = inputs.nixos-secrets.lib.secrets.shared;
      };
    in
    {
      # Empty shared secret, used for demonstration purposes
      "shared-secret" = { } // shared;

      "local-llm-api-key" = {
        owner = "goll";
      }
      // shared;
    };

  users.mutableUsers = false;

  users.users.goll = {
    isNormalUser = true;
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = authorizedKeys;

    extraGroups = [ "wheel" ];
  };

  users.users.root.shell = pkgs.zsh;

  # NOTE: Both roots are still shipped by the pinned cacert trust store
  # (private keys compromised); remove once nss-cacert drops them upstream.
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
  ];
}
