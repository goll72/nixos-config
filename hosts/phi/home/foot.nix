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
      };

      security = {
        osc52 = "enabled";
      };

      key-bindings = {
        # Unbind foot's clipboard copy to free it up to be used by zellij
        clipboard-copy = "none";
      };
    };
  };
}
