{ ... }:

{
  flake.lib.homeModules.starship =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      theme = config.nos.theme.colors;
    in
    {
      programs.starship = {
        enable = true;
        enableFishIntegration = false;

        settings = {
          add_newline = true;
          format = "[░▒▓](fg:${theme.accentDark})$os[](fg:${theme.accentDark} bg:${theme.primary})$directory[](fg:${theme.primary} bg:${theme.selection})$git_branch$git_status[](fg:${theme.selection} bg:${theme.background})$nodejs$bun$rust$golang$php[](fg:${theme.background} bg:${theme.surface})$time[ ](fg:${theme.surface})$line_break$character";

          directory = {
            style = "fg:${theme.background} bg:${theme.primary}";
            format = "[ $path ]($style)";
            truncation_length = 3;
            truncation_symbol = "…/";
            substitutions = {
              Documents = "󰈙 ";
              Downloads = " ";
              Music = " ";
              Pictures = " ";
            };
          };

          git_branch = {
            symbol = "";
            style = "bg:${theme.selection}";
            format = "[[ $symbol $branch ](fg:${theme.primary} bg:${theme.selection})]($style)";
          };

          git_status = {
            style = "bg:${theme.selection}";
            format = "[[($all_status$ahead_behind )](fg:${theme.primary} bg:${theme.selection})]($style)";
          };

          nodejs = {
            symbol = "";
            style = "bg:${theme.background}";
            format = "[[ $symbol ($version) ](fg:${theme.primary} bg:${theme.background})]($style)";
          };

          bun = {
            symbol = "";
            style = "bg:${theme.background}";
            format = "[[ $symbol ($version) ](fg:${theme.primary} bg:${theme.background})]($style)";
          };

          rust = {
            symbol = "";
            style = "bg:${theme.background}";
            format = "[[ $symbol ($version) ](fg:${theme.primary} bg:${theme.background})]($style)";
          };

          golang = {
            symbol = "";
            style = "bg:${theme.background}";
            format = "[[ $symbol ($version) ](fg:${theme.primary} bg:${theme.background})]($style)";
          };

          php = {
            symbol = "";
            style = "bg:${theme.background}";
            format = "[[ $symbol ($version) ](fg:${theme.primary} bg:${theme.background})]($style)";
          };

          time = {
            disabled = false;
            time_format = "%R";
            style = "bg:${theme.surface}";
            format = "[[  $time ](fg:${theme.foreground} bg:${theme.surface})]($style)";
          };

          os = {
            disabled = false;
            style = "bg:${theme.accentDark} fg:${theme.background}";
            format = "[ $symbol ]($style)";
            symbols = {
              Windows = "󰍲";
              Ubuntu = "󰕈";
              SUSE = "";
              Raspbian = "󰐿";
              Mint = "󰣭";
              Macos = "󰀵";
              Manjaro = "";
              Linux = "󰌽";
              NixOS = "";
              Gentoo = "󰣨";
              Fedora = "󰣛";
              Alpine = "";
              Amazon = "";
              Android = "";
              AOSC = "";
              Arch = "󰣇";
              Artix = "󰣇";
              EndeavourOS = "";
              CentOS = "";
              Debian = "󰣚";
              Redhat = "󱄛";
              RedHatEnterprise = "󱄛";
              Pop = "";
            };
          };

          character = {
            success_symbol = "[❯](bold ${theme.primary})";
            error_symbol = "[❯](bold ${theme.primary})";
          };
        };
      };

      programs.fish.interactiveShellInit = lib.mkAfter ''
        if test "$TERM" != dumb
          set -gx STARSHIP_CONFIG ${config.xdg.configHome}/starship.toml

          ${pkgs.coreutils}/bin/env \
            PATH=${config.programs.starship.package}/bin \
            ${config.programs.starship.package}/bin/starship init fish --print-full-init | source
        end
      '';
    };
}
