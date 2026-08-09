{ ... }:

{
  flake.lib.homeModules.starship =
    { config, ... }:

    {
      programs.starship = {
        enable = true;
        enableFishIntegration = true;

        settings = {
          # Stylix 26.05 exposes Base16 A-F keys with uppercase suffixes,
          # while Starship palette references ignore uppercase names.
          palettes.base16 = with config.lib.stylix.colors.withHashtag; {
            base0a = base0A;
            base0b = base0B;
            base0c = base0C;
            base0d = base0D;
            base0e = base0E;
            base0f = base0F;
          };

          add_newline = true;
          format = "[░▒▓](fg:base0d)$os[](bg:base0e fg:base0d)$directory[](fg:base0e bg:base02)$git_branch$git_status[](fg:base02 bg:base01)$nodejs$bun$rust$golang$php[](fg:base01 bg:base00)$time[ ](fg:base00)$line_break$character";

          directory = {
            style = "fg:base00 bg:base0e";
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
            style = "bg:base02";
            format = "[[ $symbol $branch ](fg:base0e bg:base02)]($style)";
          };

          git_status = {
            style = "bg:base02";
            format = "[[($all_status$ahead_behind )](fg:base0e bg:base02)]($style)";
          };

          nodejs = {
            symbol = "";
            style = "bg:base01";
            format = "[[ $symbol ($version) ](fg:base0e bg:base01)]($style)";
          };

          bun = {
            symbol = "";
            style = "bg:base01";
            format = "[[ $symbol ($version) ](fg:base0e bg:base01)]($style)";
          };

          rust = {
            symbol = "";
            style = "bg:base01";
            format = "[[ $symbol ($version) ](fg:base0e bg:base01)]($style)";
          };

          golang = {
            symbol = "";
            style = "bg:base01";
            format = "[[ $symbol ($version) ](fg:base0e bg:base01)]($style)";
          };

          php = {
            symbol = "";
            style = "bg:base01";
            format = "[[ $symbol ($version) ](fg:base0e bg:base01)]($style)";
          };

          time = {
            disabled = false;
            time_format = "%R";
            style = "bg:base00";
            format = "[[  $time ](fg:base04 bg:base00)]($style)";
          };

          os = {
            disabled = false;
            style = "bg:base0d fg:base00";
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
            success_symbol = "[❯](bold base0d)";
            error_symbol = "[❯](bold base0d)";
          };
        };
      };
    };
}
