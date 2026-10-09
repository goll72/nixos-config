# GNOME Shell extensions:
# - installed system-wide through `environment.systemPackages`
# - enabled per-user through dconf (see home/gnome.nix)
#
# This file is the single source of truth for the enabled extensions.
{ pkgs, lib }:

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

  # Each extension is installed under a directory named after its UUID,
  # so the two never have to be kept in sync by hand.
  uuids = lib.concatMap (
    extension: builtins.attrNames (builtins.readDir "${extension}/share/gnome-shell/extensions")
  ) items;
in

{
  inherit items uuids;
}
