{
  lib,
  ...
}:

{
  home.activation.ensureSshDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $HOME/.ssh/config.d $HOME/.ssh/known_hosts.d
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        addKeysToAgent = true;
        identityFile = "~/.ssh/%k.id";
        userKnownHostsFile = "~/.ssh/known_hosts.d/%k";
      };
    };

    # Non-declarative drop-ins
    includes = [ "config.d/*.conf" ];
  };
}
