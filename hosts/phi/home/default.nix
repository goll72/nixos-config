{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./firefox.nix
    ./foot.nix
    ./git.nix
    ./gnome.nix
    ./helix.nix
    ./obs-studio.nix
    ./seekey.nix
    ./ssh.nix
    ./zellij.nix
    ./zsh.nix

    ../../../modules/home/zerostack.nix
  ];

  home.username = "goll";
  home.homeDirectory = "/home/goll";
  home.backupFileExtension = "bak";
  home.overwriteBackup = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = "${config.home.homeDirectory}/desktop";
    documents = "${config.home.homeDirectory}/documents";
    download = "${config.home.homeDirectory}/downloads";
    music = "${config.home.homeDirectory}/media/music";
    pictures = "${config.home.homeDirectory}/media/pictures";
    videos = "${config.home.homeDirectory}/media/videos";
    publicShare = "${config.home.homeDirectory}/media/public";
    templates = "${config.home.homeDirectory}/media/templates";
    projects = "${config.home.homeDirectory}/projects";

    setSessionVariables = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];

    config.common.default = [ "gtk" ];
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
  };

  programs.htop = {
    enable = true;

    settings = {
      # ...
    };
  };

  programs.yt-dlp = {
    enable = true;

    # ...
  };

  programs.zsh = {
    enable = true;

    # ...
  };

  home.stateVersion = "26.11";
}
