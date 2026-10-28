{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.zerostack;
  toml = pkgs.formats.toml { };
in
{
  options.programs.zerostack = {
    enable = lib.mkEnableOption "zerostack, a lightweight coding agent written in Rust";

    settings = lib.mkOption {
      type = toml.type;
      default = { };
      description = ''
        zerostack configuration, serialized to TOML.
      '';
      example = {
        provider = "llama-local";
        model = "qwen";
        custom_providers.llama-local = {
          base_url = "http://127.0.0.1:8080/v1";
        };
        quick_models.qwen = {
          provider = "llama-local";
          model = "qwen-model-id";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.dataFile."zerostack/config.toml".source = toml.generate "zerostack-config.toml" cfg.settings;
  };
}
