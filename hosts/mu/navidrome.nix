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

      # XXX: Temporary fix for https://github.com/NixOS/nixpkgs/issues/578796
      # until I update to a nixpkgs revision that has the proper fix merged
      Plugins.Enabled = false;
    };
  };
}
