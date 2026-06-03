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
          --color=fg:${colors.fg} \
          --color=fg+:${colors.fg} \
          --color=bg:${colors.bg} \
          --color=bg+:${colors.bgLight} \
          --color=hl:${colors.primary} \
          --color=hl+:${colors.primary} \
          --color=info:${colors.fgDark} \
          --color=border:${colors.fgDark} \
          --color=separator:${colors.fgDark} \
          --color=scrollbar:${colors.fgDark} \
          --color=label:${colors.primary} \
          --color=prompt:${colors.primary} \
          --color=pointer:${colors.primary} \
          --color=marker:${colors.secondary} \
          --color=spinner:${colors.tertiary} \
          --color=header:${colors.fgDark} \
          --color=gutter:${colors.bgLight} \
          --color=query:${colors.fg}"
      '';
    };
}
