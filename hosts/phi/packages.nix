{
  pkgs,
  ...
}:

{
  environment.systemPackages = [
    pkgs.android-tools
    pkgs.bubblewrap
    pkgs.delta
    pkgs.gh
    pkgs.hyperfine
    pkgs.jq
    pkgs.llama-cpp-vulkan
    pkgs.nh
    pkgs.nvtopPackages.intel
    pkgs.perf
    pkgs.pciutils
    pkgs.qrtool
    pkgs.sbctl
    pkgs.scrcpy
    pkgs.systemdUkify
    pkgs.timg
    pkgs.tinymist
    pkgs.typst
    pkgs.usbutils
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

    pkgs.noto-fonts
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-color-emoji
  ];

  # Force all emoji to render with Noto Color Emoji (e.g. in foot).
  #
  # Fira Code ships a handful of emoji/symbol codepoints (arrows, dingbats,
  # misc symbols, pictographs).  foot picks the first font in its fallback
  # chain that has a glyph, so it drew those with Fira Code's monochrome glyphs
  # instead of falling through to Noto Color Emoji.  Stripping those codepoints
  # from Fira Code's charset lets fontconfig reach Noto Color Emoji.
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <match target="scan">
        <test name="family" compare="eq"><string>Fira Code</string></test>
        <edit name="charset" mode="assign" binding="same">
          <minus>
            <name>charset</name>
            <charset>
              <range><int>0x2190</int><int>0x21ff</int></range>
              <range><int>0x2600</int><int>0x27bf</int></range>
              <range><int>0x2b00</int><int>0x2bff</int></range>
              <range><int>0xfe00</int><int>0xfe0f</int></range>
              <range><int>0x1f000</int><int>0x1faff</int></range>
            </charset>
          </minus>
        </edit>
      </match>
    </fontconfig>
  '';
}
