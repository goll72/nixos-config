{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.bubblewrap
    pkgs.delta
    pkgs.gh
    pkgs.hyperfine
    pkgs.jq
    pkgs.llama-cpp-vulkan
    pkgs.ldns
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
