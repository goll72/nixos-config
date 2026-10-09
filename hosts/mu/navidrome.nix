{
  meta,
  pkgs,
  ...
}:

{
  services.navidrome = {
    enable = true;

    settings = {
      MusicFolder = "/var/lib/music";
      FFmpegPath = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
      BaseUrl = "https://mu.${meta.domain}";
    };
  };
}
