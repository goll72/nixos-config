{
  lib,
  pkgs,
  ...
}:

let
  extensions = import ./extensions.nix { inherit pkgs; };
  theme = import ./gnome-theme.nix;
in

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.gnome = {
    core-apps.enable = false;
    core-developer-tools.enable = false;
    games.enable = false;

    localsearch.enable = false;
    at-spi2-core.enable = lib.mkForce false;

    gnome-remote-desktop.enable = false;
    gnome-browser-connector.enable = false;
  };

  i18n.inputMethod.enable = false;

  environment.gnome.excludePackages = [
    pkgs.gnome-tour
    pkgs.gnome-user-docs
  ];

  environment.systemPackages = extensions.items ++ [
    # Available system-wide so the GDM greeter can use it as well
    # (the user session gets it through gtk.iconTheme in home/gnome.nix)
    pkgs.papirus-icon-theme
  ];

  # The GDM greeter runs as its own user and does not read the goll dconf
  # settings, so give it the same fonts and icon theme through its own
  # dconf profile. Placed first in the profile so these keys win over
  # GDM's greeter-dconf-defaults.
  programs.dconf.profiles.gdm.databases = lib.mkBefore [
    {
      settings."org/gnome/desktop/interface" = {
        icon-theme = theme.iconTheme;
        font-name = theme.fonts.ui;
        document-font-name = theme.fonts.document;
        monospace-font-name = theme.fonts.monospace;
      };
    }
  ];
}
