{
  lib,
  meta,
  pkgs,
  ...
}:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "goll";
        email = meta.email;
      };

      init.defaultBranch = "main";

      core.pager = "${pkgs.delta}/bin/delta";
      interactive.difffilter = "${pkgs.delta}/bin/delta --color-only";

      # diff/blame pager for git
      delta =
        let
          quote = x: ''"${x}"'';
        in
        {
          navigate = true;
          hyperlinks = true;
          features = "secular-tardigrade";

          "secular-tardigrade" = {
            dark = true;
            line-numbers = false;
            side-by-side = false;
            keep-plus-minus-markers = false;
            syntax-theme = "Nord";

            file-style = "white";
            file-decoration-style = "white ul";
            file-added-label = quote "[+]";
            file-copied-label = quote "[=]";
            file-modified-label = quote "[*]";
            file-removed-label = quote "[-]";
            file-renamed-label = quote "[>]";

            hunk-header-style = "file line-number";
            hunk-header-decoration-style = quote "#838CAE";
            hunk-label = quote "::";

            minus-style = "normal ${quote "#841414"}";
            minus-emph-style = "normal ${quote "#B12222"}";
            plus-style = "normal ${quote "#289030"}";
            plus-emph-style = "normal ${quote "#2BB03C"}";

            zero-style = "normal";

            blame-code-style = "syntax";
            blame-format = quote "{author:<18.17} ({commit:>8}) {timestamp:^16}";
            blame-palette = lib.concatMapStringsSep " " quote [
              "#181818"
              "#242424"
              "#131313"
              "#303030"
            ];
            blame-separator-format = quote "{n:5}▒";

            merge-conflict-begin-symbol = quote "~";
            merge-conflict-end-symbol = quote "~";
            merge-conflict-ours-diff-header-style = "${quote "#F1FA8C"} bold";
            merge-conflict-ours-diff-header-decoration-style = "${quote "#434C5E"} box";
            merge-conflict-theirs-diff-header-style = "${quote "#F1FA8C"} bold";
            merge-conflict-theirs-diff-header-decoration-style = "${quote "#434C5E"} box";
          };
        };

      diff.colorMoved = "default";

    };
  };
}
