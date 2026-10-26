{
  meta,
  pkgs,
  ...
}:

{
  services.navidrome = {
    enable = true;

    settings = {
      MusicFolder = "/srv/nfs/music";
      FFmpegPath = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
      BaseUrl = "https://mu.${meta.domain}";
    };
  };
}
