{
  lib,
  inputs,
  osConfig,
  ...
}:

{
  programs.helix = {
    enable = true;

    settings =
      let
        shared-keybinds = {
          A-m = ":lsp-workspace-command";
          A-0 = ":lsp-workspace-command tinymist.pinMain \"%sh{realpath %{buffer_name}}\"";
        };
      in
      {
        theme = "fleet_dark_transparent";

        keys = {
          normal = shared-keybinds;
          insert = shared-keybinds;
        };
      };

    languages = {
      language =
        let
          # mergeAttrsListBasedOnKey :: (AttrSet -> a) -> [AttrSet] -> [AttrSet]
          mergeAttrsListBasedOnKey =
            f: list:
            let
              f' =
                { reduced, rest }:
                if rest == [ ] then
                  {
                    inherit reduced;
                    inherit rest;
                  }
                else
                  let
                    y = builtins.head rest;
                    p = lib.lists.partition (x: f x == f y) rest;
                  in
                  f' {
                    reduced = reduced ++ [ (lib.attrsets.mergeAttrsList p.right) ];
                    rest = p.wrong;
                  };

              self = f' {
                reduced = [ ];
                rest = list;
              };
            in
            self.reduced;

          deeplyIndent = x: {
            name = x;

            indent = {
              tab-width = 4;
              unit = "    ";
            };
          };
        in
        mergeAttrsListBasedOnKey (x: x.name) [
          {
            name = "nix";
            auto-format = true;
          }
        ]
        ++ (map deeplyIndent [
          "c"
          "cpp"
          "css"
          "html"
          "python"
        ]);

      language-server = {
        nixd = {
          command = "nixd";
          args = [ "--semantic-tokens=true" ];

          config.nixd =
            let
              # Reference the flake by its store path (string-quoted so the
              # path lands in the generated config verbatim, keeping the
              # source alive through closure reference scanning) instead of
              # a machine-specific checkout path.
              here = "(builtins.getFlake ${builtins.toJSON (lib.toString inputs.self)})";
              nixosOpts = "${here}.nixosConfigurations.${osConfig.networking.hostName}.options";
            in
            {
              nixpkgs.expr = "import ${here}.inputs.nixpkgs {}";
              formatting.command = [ "nixfmt" ];
              options = {
                nixos.expr = nixosOpts;
                home-manager.expr = "${nixosOpts}.home-manager.users.type.getSubOptions []";
              };
            };
        };
      };
    };

    themes = {
      fleet_dark_transparent =
        let
          transparent = "none";
        in
        {
          inherits = "fleet_dark";
          "ui.background" = transparent;
        };
    };
  };
}
