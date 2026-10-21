{
  lib,
  meta,
  config,
  ...
}:

let
  hostname = config.networking.hostName;

  domainReversed = lib.concatStringsSep "." (
    lib.lists.reverseList (lib.strings.splitString "." meta.domain)
  );
in
{
  networking.useDHCP = true;

  networking.firewall.enable = false;

  # The local resolver prepends 127.0.0.1/::1 to resolv.conf via
  # openresolv (useLocalResolver is set by the local-dns module).
  services.local-dns.enable = true;
  services.knot-zone-watch.enable = true;

  environment.enableAllTerminfo = true;

  services.wireguard-vpn = {
    phi = {
      name = "phi.net";
      interface = "wg.phi";
      backend = "wireguard";
      privateKeySecret = "wg-key";
    };

    lambda = {
      name = "lambda.net";
      interface = "wg.lambda";
      backend = "wireguard";
      privateKeySecret = "wg-key";
    };
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.${meta.domainCreatedAt}.${domainReversed}:${hostname}";
  };

  services.journald.settings.Journal.SystemMaxUse = "100M";

  security.sudo.wheelNeedsPassword = false;

  programs.zsh = {
    enableLsColors = true;
    enableCompletion = true;

    shellInit = ''
      autoload -Uz add-zsh-hook

      set_term_title() {
        print -Pn '\e]0;%m:%1~\a'
      }

      add-zsh-hook precmd set_term_title
    '';
  };
}
