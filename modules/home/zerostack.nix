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
    enable = lib.mkEnableOption "ZeroStack";

    settings = lib.mkOption {
      type = toml.type;
      default = { };
      description = ''
        ZeroStack configuration, serialized to TOML.
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
    xdg.configFile."zerostack/config.toml".source = toml.generate "zerostack-config.toml" cfg.settings;
  };
}
