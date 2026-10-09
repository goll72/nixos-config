{
  programs.zellij = {
    enable = true;

    settings = {
      theme = "ansi";
      copy_on_select = false;

      show_startup_tips = false;
      show_release_notes = false;
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
