{ ... }:

{
  programs.maki = {
    enable = true;

    settings = {
      ui = {
        splash_animation = false;
        theme = "system";
        scrollbar = false;
      };
      trust.paths = [
        "/etc/nixos"
        "~/projects/*"
        "~/projects/_/*"
      ];
    };

    providers.llama-cpp.base_url = "http://localhost:9931";
  };
}
