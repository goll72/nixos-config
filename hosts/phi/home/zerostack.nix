{ ... }:

{
  programs.zerostack = {
    enable = true;

    settings = {
      provider = "openrouter";
      compact_enabled = true;
      mid_turn_compact_threshold = 0.9;
      edit_system = "similarity";
      default_prompt = "code";
      default_permission_mode = "standard";
      show_tool_details = 3;

      sandbox = true;

      custom_providers.local = {
        provider_type = "openai";
        base_url = "http://localhost:9931/v1";
      };

      permission = {
        external_directory = {
          "/nix/store/**" = "allow";
          "/tmp/**" = "allow";
          "/**" = "ask";
          "/run/**" = "deny";
        };

        doom_loop = "ask";
      };
    };
  };
}
