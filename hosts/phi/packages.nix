{
  lib,
  pkgs,
  config,
  ...
}:

{
  environment.systemPackages =
    let
      var = x: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] x);

      api-keys = [
        "openrouter-api-key"
        "local-llm-api-key"
      ];

      zerostack-with-api-keys = pkgs.writeShellApplication {
        name = "zerostack";
        text = ''
          ${lib.concatMapStringsSep "\n" (
            x: ''${var x}="$(< ${config.sops.secrets.${x}.path})"; export ${var x}''
          ) api-keys}
          exec ${lib.getExe pkgs.zerostack} "$@"
        '';
      };
    in
    [
      pkgs.bubblewrap
      pkgs.delta
      pkgs.gh
      pkgs.hyperfine
      pkgs.jq
      pkgs.knot-dns
      pkgs.llama-cpp-vulkan
      pkgs.nh
      pkgs.nvtopPackages.intel
      pkgs.perf
      pkgs.qrtool
      pkgs.sbctl
      pkgs.scrcpy
      pkgs.timg
      pkgs.tinymist
      pkgs.typst
      pkgs.wl-clipboard

      zerostack-with-api-keys

      pkgs.dosbox-x
      pkgs.gimp3
      pkgs.gnome-calculator
      pkgs.gnome-calendar
      pkgs.hylki
      pkgs.inkscape
      pkgs.kdePackages.kdenlive
      pkgs.nautilus
      pkgs.pawse
      pkgs.pwvucontrol
      pkgs.retroarch
      pkgs.rustdesk-flutter
      pkgs.seekey
      pkgs.snapshot
      pkgs.surfer
      pkgs.wireshark

      # Used as the default terminal application
      pkgs.xdg-terminal-exec
    ];

  fonts.packages = [
    pkgs.fira-code
    pkgs.fira-math
    pkgs.fira-mono
    pkgs.fira-sans
  ];
}
