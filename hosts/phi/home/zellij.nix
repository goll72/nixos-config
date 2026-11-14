{
  pkgs,
  ...
}:
{
  programs.zellij = {
    enable = true;

    settings = {
      theme_dark = "ansi";
      theme_light = "solarized-light";
      copy_on_select = false;

      show_startup_tips = false;
      show_release_notes = false;

      default_shell = "${pkgs.zsh}/bin/zsh";
    };

    # Use the usual terminal copy keybind to copy zellij selections
    extraConfig = ''
      keybinds {
        shared {
          bind "Ctrl Shift c" { Copy; }
        }
      }
    '';
  };
}
