# GNOME fonts and icon theme, shared between the GDM greeter profile
# (desktop.nix) and the user session (home/gnome.nix) so the two can
# never drift apart.
{
  iconTheme = "Papirus-Dark";

  fonts = {
    ui = "Fira Sans 12";
    document = "Fira Sans 11";
    monospace = "Fira Mono 11";
  };
}
