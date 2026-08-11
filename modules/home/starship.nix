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
      stylix = config.lib.stylix.colors.withHashtag;
      ttyConfig = (pkgs.formats.toml { }).generate "starship-tty.toml" {
        add_newline = false;
        format = "$directory$git_branch$git_status$line_break$character";

        directory = {
          format = "[$path]($style) ";
          style = "bold white";
          truncation_length = 3;
          truncation_symbol = ".../";
        };

        git_branch = {
          format = "[$symbol$branch]($style) ";
          style = "dimmed white";
          symbol = "git:";
        };

        git_status = {
          format = "[$all_status$ahead_behind]($style) ";
          style = "dimmed white";
        };

        character = {
          success_symbol = "[>](bold white)";
          error_symbol = "[>](bold white)";
        };
      };
    in
    {
      programs.starship = {
        enable = true;
        enableFishIntegration = false;

        settings = {
          add_newline = true;
          format = "[░▒▓](fg:${stylix.base0F})$os[](fg:${stylix.base0F} bg:${stylix.base0D})$directory[](fg:${stylix.base0D} bg:${stylix.base02})$git_branch$git_status[](fg:${stylix.base02} bg:${stylix.base00})$nodejs$bun$rust$golang$php[](fg:${stylix.base00} bg:${stylix.base01})$time[ ](fg:${stylix.base01})$line_break$character";

          directory = {
            style = "fg:${stylix.base00} bg:${stylix.base0D}";
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
            style = "bg:${stylix.base02}";
            format = "[[ $symbol $branch ](fg:${stylix.base0D} bg:${stylix.base02})]($style)";
          };

          git_status = {
            style = "bg:${stylix.base02}";
            format = "[[($all_status$ahead_behind )](fg:${stylix.base0D} bg:${stylix.base02})]($style)";
          };

          nodejs = {
            symbol = "";
            style = "bg:${stylix.base00}";
            format = "[[ $symbol ($version) ](fg:${stylix.base0D} bg:${stylix.base00})]($style)";
          };

          bun = {
            symbol = "";
            style = "bg:${stylix.base00}";
            format = "[[ $symbol ($version) ](fg:${stylix.base0D} bg:${stylix.base00})]($style)";
          };

          rust = {
            symbol = "";
            style = "bg:${stylix.base00}";
            format = "[[ $symbol ($version) ](fg:${stylix.base0D} bg:${stylix.base00})]($style)";
          };

          golang = {
            symbol = "";
            style = "bg:${stylix.base00}";
            format = "[[ $symbol ($version) ](fg:${stylix.base0D} bg:${stylix.base00})]($style)";
          };

          php = {
            symbol = "";
            style = "bg:${stylix.base00}";
            format = "[[ $symbol ($version) ](fg:${stylix.base0D} bg:${stylix.base00})]($style)";
          };

          time = {
            disabled = false;
            time_format = "%R";
            style = "bg:${stylix.base01}";
            format = "[[  $time ](fg:${stylix.base05} bg:${stylix.base01})]($style)";
          };

          os = {
            disabled = false;
            style = "bg:${stylix.base0F} fg:${stylix.base00}";
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
            success_symbol = "[❯](bold ${stylix.base0D})";
            error_symbol = "[❯](bold ${stylix.base0D})";
          };
        };
      };

      programs.fish.interactiveShellInit = lib.mkAfter ''
        if test "$TERM" != dumb
          if test "$TERM" = linux
            set -gx STARSHIP_CONFIG ${ttyConfig}
          end

          ${pkgs.coreutils}/bin/env \
            PATH=${config.programs.starship.package}/bin \
            ${config.programs.starship.package}/bin/starship init fish --print-full-init | source
        end
      '';
    };
}
