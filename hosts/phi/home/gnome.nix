{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  extensions = import ../extensions.nix { inherit pkgs; };
  theme = import ../gnome-theme.nix;

  xkb = osConfig.services.xserver.xkb;
in

{
  gtk = {
    enable = true;

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = theme.iconTheme;
    };

    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
  };

  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      sources = [
        (lib.hm.gvariant.mkTuple [
          "xkb"
          xkb.layout
        ])
      ];
      mru-sources = [
        (lib.hm.gvariant.mkTuple [
          "xkb"
          xkb.layout
        ])
      ];
    };

    "org/gnome/desktop/interface" = {
      accent-color = "slate";
      color-scheme = "prefer-dark";

      font-name = theme.fonts.ui;
      document-font-name = theme.fonts.document;
      monospace-font-name = theme.fonts.monospace;

      clock-show-weekday = true;

      font-antialiasing = "rgba";
    };

    "org/gnome/desktop/background" =
      let
        wallpaper = ../../../assets/wallpaper/image.jpg;
      in
      {
        picture-uri = "file://${wallpaper}";
        picture-uri-dark = "file://${wallpaper}";
      };

    "org/gnome/desktop/peripherals/touchpad" = {
      tap-and-drag = true;
      two-finger-scrolling-enabled = true;
      natural-scroll = true;
      disable-while-typing = true;
      click-method = "areas";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    "org/gnome/shell" = {
      enabled-extensions = extensions.uuids;
    };

    "org/gnome/shell/extensions/app-hider" =
      let
        desktopEntries = entries: map (x: "${x}.desktop") entries;

        hidden = desktopEntries [
          "footclient"
          "foot-server"
          "Helix"
          "htop"
          "nvtop"
          "scrcpy-console"
        ];
      in
      {
        # NixOS Manual should still be available when searching
        hidden-apps = hidden ++ desktopEntries [ "nixos-manual" ];
        hidden-search-apps = hidden;
      };

    "org/gnome/shell/extensions/bluetooth-quick-connect" = {
      show-battery-value-on = true;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel".blur = false;
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock".blur = false;
    "org/gnome/shell/extensions/blur-my-shell/appfolder".blur = false;

    "org/gnome/shell/extensions/display-brightness-ddcutil" = {
      # 0 -> Top Bar, 1 -> System Menu
      button-location = 1;
    };

    "org/gnome/shell/extensions/hibernate-power-menu" = {
      show-hybrid-sleep = false;
    };

    "org/gnome/shell/extensions/just-perfection" = {
      window-demands-attention-focus = true;
      quick-settings-airplane-mode = false;
    };

    "org/gnome/shell/extensions/rounded-window-corners-reborn" =
      let
        gv = lib.hm.gvariant;

        # attrset -> GVariant dict a{s <elemType>}; values typed implicitly or by constructor
        dict =
          elemType: attrs:
          gv.mkArray elemType (
            lib.mapAttrsToList (
              k: v:
              gv.mkDictionaryEntry [
                k
                v
              ]
            ) attrs
          );

        # attrset -> a{s v} dict, each value wrapped in a variant
        vdict = attrs: dict "{sv}" (lib.mapAttrs (k: v: gv.mkVariant v) attrs);

        # NOTE: the additional top padding must match the height of the
        # titlebar to make up for foot drawing it as a separate window
        padding = 4;
        additional-top-padding = 26;
      in
      {
        custom-rounded-corner-settings = vdict {
          foot = vdict {
            enabled = true;

            padding = dict "{su}" {
              left = gv.mkUint32 padding;
              right = gv.mkUint32 padding;
              top = gv.mkUint32 (padding + additional-top-padding);
              bottom = gv.mkUint32 padding;
            };
            keepRoundedCorners = dict "{sb}" {
              maximized = false;
              fullscreen = false;
            };
            borderRadius = gv.mkUint32 12;
            smoothing = 0.1;
            borderColor = gv.mkTuple [
              0.5
              0.5
              0.5
              1.0
            ];
          };
        };

        blacklist = [
          "dev.seekey"
          "seekey"
        ];
      };

    "org/gnome/shell/extensions/wiggle" = {
      magnify-duration = 200;
      unmagnify-duration = 150;
      unmagnify-delay = 200;

      check-interval = 200;
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-from = 22.0;
      night-light-schedule-to = 6.0;
      night-light-temperature = lib.hm.gvariant.mkUint32 2400;
    };

    "org/gnome/mutter" = {
      experimental-features = [ "autoclose-xwayland" ];
    };
  };
}
