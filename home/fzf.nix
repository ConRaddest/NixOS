{ ... }:

{
  flake.lib.homeModules.fzf =
    { colors, ... }:

    {
      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
      };

      # FZF colors are set via FZF_DEFAULT_OPTS in bash.initExtra rather than
      # programs.fzf.colors, because home.sessionVariables only applies to
      # login shells and Kitty under Hyprland opens non-login bash.
      programs.bash.initExtra = ''
        export FZF_DEFAULT_OPTS=" \
          --color=fg:${colors.text} \
          --color=fg+:${colors.text} \
          --color=bg:${colors.base} \
          --color=bg+:${colors.overlay} \
          --color=hl:${colors.accent} \
          --color=hl+:${colors.accent} \
          --color=info:${colors.muted} \
          --color=border:${colors.muted} \
          --color=separator:${colors.muted} \
          --color=scrollbar:${colors.muted} \
          --color=label:${colors.accent} \
          --color=prompt:${colors.accent} \
          --color=pointer:${colors.accent} \
          --color=marker:${colors.purple} \
          --color=spinner:${colors.accent} \
          --color=header:${colors.muted} \
          --color=gutter:${colors.overlay} \
          --color=query:${colors.text}"
      '';
    };
}
