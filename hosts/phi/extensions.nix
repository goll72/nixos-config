# GNOME Shell extensions:
# - installed system-wide through `environment.systemPackages`
# - enabled per-user through dconf (see home/gnome.nix)
#
# This file is the single source of truth for the enabled extensions.
{ pkgs }:

let
  items = [
    pkgs.gnomeExtensions.app-hider
    pkgs.gnomeExtensions.blur-my-shell
    pkgs.gnomeExtensions.bluetooth-quick-connect
    pkgs.gnomeExtensions.brightness-control-using-ddcutil
    pkgs.gnomeExtensions.caffeine
    pkgs.gnomeExtensions.hibernate-power-menu
    pkgs.gnomeExtensions.just-perfection
    pkgs.gnomeExtensions.rounded-window-corners-reborn
    pkgs.gnomeExtensions.wiggle
  ];

  # Each extension package exposes the UUID of the directory it installs
  # under (nixpkgs' buildGnomeExtension and the in-repo extension packages
  # all set passthru.extensionUuid), so the two never have to be kept in
  # sync by hand.
  uuids = map (extension: extension.extensionUuid) items;
in

{
  inherit items uuids;
}
