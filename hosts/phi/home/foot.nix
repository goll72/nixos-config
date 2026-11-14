{ ... }:

{
  programs.foot = {
    enable = true;

    settings = {
      bell = {
        urgent = "yes";
      };

      csd = {
        button-color = "ffcdcdcd";
        # Chosen to match default background color
        color = "ff242424";
        font = "Fira Sans:weight=Medium";
        preferred = "client";
        hide-when-maximized = "yes";
      };

      cursor = {
        blink = "yes";
        style = "block";
      };

      main = {
        dpi-aware = "yes";
        font = "Fira Code:size=7";
        underline-offset = 1;
        shell = "zellij";
        initial-color-theme = "dark";
      };

      security = {
        osc52 = "enabled";
      };

      key-bindings = {
        # Unbind foot's clipboard copy to free it up to be used by zellij
        clipboard-copy = "none";
        # Toggle between the dark and light color themes
        color-theme-toggle = "Control+Shift+m";
      };

      colors-light = {
        background = "f6f6f8";
        foreground = "242424";
        regular0 = "242424";
        regular1 = "d64550";
        regular2 = "3f9d4d";
        regular3 = "b58900";
        regular4 = "1971c2";
        regular5 = "9c36b5";
        regular6 = "0891b2";
        regular7 = "57606f";
        bright0 = "868e96";
        bright1 = "e5484d";
        bright2 = "40c057";
        bright3 = "f2c94c";
        bright4 = "4c8bf5";
        bright5 = "bf4fd6";
        bright6 = "2aa198";
        bright7 = "9ca0c0";
      };

      tweak = {
        # As much as I would like to keep this enabled, the resulting
        # behavior from terminal programs is too inconsistent/fragile
        grapheme-shaping = "no";
      };
    };
  };
}
