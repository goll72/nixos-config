{
  config,
  ...
}:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;

    enableCompletion = true;
    autosuggestion.enable = true;

    history.append = true;

    initContent = ''
      zstyle ':completion:*' menu select

      autoload -Uz add-zsh-hook
      autoload -Uz vcs_info

      zstyle ':vcs_info:git:*' check-for-changes true
      zstyle ':vcs_info:git:*' get-revision true
      zstyle ':vcs_info:git:*' formats ' (%b%u%c)'
      zstyle ':vcs_info:git:*' unstagedstr ' %F{red}!%f'
      zstyle ':vcs_info:git:*' stagedstr ' %F{yellow}+%f'

      setopt PROMPT_SUBST
      PROMPT='%4~$vcs_info_msg_0_ %# '
      RPROMPT='%(?..%F{red}<<%f)'

      add-zsh-hook precmd vcs_info
    '';
  };
}
