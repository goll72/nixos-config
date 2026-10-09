{
  xdg.configFile."seekey/config.ini" = {
    enable = true;

    text = ''
      [general]
      duration-ms=1200
      typing-idle-ms=650
      fade-ms=180
      margin=0
      margin-horizontal=0
      max-items=5
      # window-width equal to the main display's width so that
      # the overlay will always be properly aligned vertically
      window-width=1920
      window-height=60
      layer-shell=auto
      typing-display=full
      merge-repeats=true
      merge-modifiers=true
      show-mouse=false
      theme=default

      [style]
      align=left
      disappear=fade
      spacing=7
      overlay-padding=12
      key-min-width=0
      key-padding-x=14
      key-padding-y=8
      key-radius=12
      key-border-width=1
      key-font-px=20
      key-font-weight=700
      typing-max-width=480
      font-family=inherit
      foreground=#f7f7f2
      background=alpha(#111318, 0.86)
      border-color=alpha(#ffffff, 0.)
      shadow=0 alpha(#000000, 0)
      placeholder-text=Alt + ␣  :  Shift + ↑/↓  :  ↵
      placeholder-foreground=alpha(#f7f7f2, 0.74)
      placeholder-background=alpha(#111318, 0.56)
      placeholder-border-color=alpha(#ffffff, 0.14)

      [icons]
      Esc=Esc
      Home=Home
      End=End
      Page Up=PgUp
      Page Down=PgDn
      Num Enter=Num ↵
    '';
  };
}
