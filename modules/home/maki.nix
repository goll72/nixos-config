{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.maki;
in
{
  options.programs.maki = {
    enable = lib.mkEnableOption "maki, an efficient AI coding agent extendable by neovim-like Lua plugins";

    package = lib.mkPackageOption pkgs "maki" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = lib.literalExpression ''
        {
          ui = {
            splash_animation = true;
            mouse_scroll_lines = 5;
            theme = "tokyonight";
            tool_output_lines = {
              bash = 8;
              read = 5;
            };
          };
          agent.max_output_lines = 3000;
          provider.default_model = "openrouter/auto";
          storage.max_log_files = 5;
          plugins = {
            bash.timeout_secs = 180;
            index.max_file_size_mb = 4;
          };
        }
      '';
      description = ''
        Configuration passed to `maki.setup()` in
        {file}`$XDG_CONFIG_HOME/maki/init.lua`, serialized with
        `lib.generators.toLua`. Values created with
        `lib.generators.mkLuaInline` are rendered as raw Lua
        expressions. See <https://maki.sh/docs/configuration> for the
        available options.
      '';
    };

    providers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = { };
      example = lib.literalExpression ''
        {
          llama-cpp.base_url = "http://localhost:9931";
        }
      '';
      description = ''
        Provider definitions written to
        {file}`$XDG_CONFIG_HOME/maki/providers.toml`. See
        <https://maki.sh/docs/providers/> for the available options.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = lib.literalExpression ''
        maki.keymap.set("n", "<leader>q", ":q<CR>")
      '';
      description = ''
        Extra Lua code appended to {file}`$XDG_CONFIG_HOME/maki/init.lua`,
        after the generated `maki.setup()` call. Use this for plugin
        definitions, keymaps and anything else that is not plain data.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile = {
      "maki/init.lua".text = ''
        maki.setup(${lib.generators.toLua { } cfg.settings})
        ${lib.optionalString (cfg.extraConfig != "") "\n${cfg.extraConfig}"}
      '';
    }
    // lib.optionalAttrs (cfg.providers != { }) {
      "maki/providers.toml".source = (pkgs.formats.toml { }).generate "maki-providers.toml" cfg.providers;
    };
  };
}
