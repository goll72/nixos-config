{ lib, config, ... }:

let
  cfg = config.users.avatars;
in

{
  options.users.avatars = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    default = { };

    example = {
      goll = ./assets/pfp/image.jpg;
    };

    description = ''
      Profile pictures for AccountsService, keyed by username. Each image is
      symlinked to `/var/lib/AccountsService/icons/<user>` and referenced from
      the user's AccountsService record, so it shows up in the display manager
      greeter and the user settings.
    '';
  };

  config.systemd.tmpfiles.rules = lib.concatLists (
    lib.mapAttrsToList (username: image: [
      "f+ /var/lib/AccountsService/users/${username} 0600 root root - [User]\\nIcon=/var/lib/AccountsService/icons/${username}\\n"
      "L+ /var/lib/AccountsService/icons/${username} -    -    -    - ${image}"
    ]) cfg
  );
}
