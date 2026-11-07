{
  meta,
  pkgs,
  ...
}:

{
  services.navidrome = {
    enable = true;

    withPlugins = p: [ p.lyrics-plugin ];

    settings = {
      MusicFolder = "/srv/nfs/music";
      FFmpegPath = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
      BaseUrl = "https://mu.${meta.domain}";

      # Use the nd-lyrics plugin even when there are no local lyric files
      LyricsPriority = ".ttml,.yaml,.yml,.elrc,.lrc,.srt,.txt,embedded,nd-lyrics";
    };
  };
}
