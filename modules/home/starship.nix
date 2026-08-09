{ ... }:

{
  flake.lib.homeModules.starship =
    { ... }:

    {
      programs.starship = {
        enable = true;
        enableFishIntegration = true;
      };

      xdg.configFile."matugen/templates/starship.toml".text = ''
        "$schema" = "https://starship.rs/config-schema.json"

        add_newline = true
        format = """
        [░▒▓](fg:{{colors.primary.default.hex}})\
        $os\
        [](bg:{{colors.secondary.default.hex}} fg:{{colors.primary.default.hex}})\
        $directory\
        [](fg:{{colors.secondary.default.hex}} bg:{{colors.surface_container_highest.default.hex}})\
        $git_branch\
        $git_status\
        [](fg:{{colors.surface_container_highest.default.hex}} bg:{{colors.surface_container.default.hex}})\
        $nodejs\
        $bun\
        $rust\
        $golang\
        $php\
        [](fg:{{colors.surface_container.default.hex}} bg:{{colors.surface_container_low.default.hex}})\
        $time\
        [ ](fg:{{colors.surface_container_low.default.hex}})\
        $line_break\
        $character
        """

        [directory]
        style = "fg:{{colors.on_secondary.default.hex}} bg:{{colors.secondary.default.hex}}"
        format = "[ $path ]($style)"
        truncation_length = 3
        truncation_symbol = "…/"

        [directory.substitutions]
        "Documents" = "󰈙 "
        "Downloads" = " "
        "Music" = " "
        "Pictures" = " "

        [git_branch]
        symbol = ""
        style = "bg:{{colors.surface_container_highest.default.hex}}"
        format = "[[ $symbol $branch ](fg:{{colors.secondary.default.hex}} bg:{{colors.surface_container_highest.default.hex}})]($style)"

        [git_status]
        style = "bg:{{colors.surface_container_highest.default.hex}}"
        format = "[[($all_status$ahead_behind )](fg:{{colors.secondary.default.hex}} bg:{{colors.surface_container_highest.default.hex}})]($style)"

        [nodejs]
        symbol = ""
        style = "bg:{{colors.surface_container.default.hex}}"
        format = "[[ $symbol ($version) ](fg:{{colors.secondary.default.hex}} bg:{{colors.surface_container.default.hex}})]($style)"

        [bun]
        symbol = ""
        style = "bg:{{colors.surface_container.default.hex}}"
        format = "[[ $symbol ($version) ](fg:{{colors.secondary.default.hex}} bg:{{colors.surface_container.default.hex}})]($style)"

        [rust]
        symbol = ""
        style = "bg:{{colors.surface_container.default.hex}}"
        format = "[[ $symbol ($version) ](fg:{{colors.secondary.default.hex}} bg:{{colors.surface_container.default.hex}})]($style)"

        [golang]
        symbol = ""
        style = "bg:{{colors.surface_container.default.hex}}"
        format = "[[ $symbol ($version) ](fg:{{colors.secondary.default.hex}} bg:{{colors.surface_container.default.hex}})]($style)"

        [php]
        symbol = ""
        style = "bg:{{colors.surface_container.default.hex}}"
        format = "[[ $symbol ($version) ](fg:{{colors.secondary.default.hex}} bg:{{colors.surface_container.default.hex}})]($style)"

        [time]
        disabled = false
        time_format = "%R"
        style = "bg:{{colors.surface_container_low.default.hex}}"
        format = "[[  $time ](fg:{{colors.on_surface_variant.default.hex}} bg:{{colors.surface_container_low.default.hex}})]($style)"

        [os]
        disabled = false
        style = "bg:{{colors.primary.default.hex}} fg:{{colors.on_primary.default.hex}}"
        format = "[ $symbol ]($style)"

        [os.symbols]
        Windows = "󰍲"
        Ubuntu = "󰕈"
        SUSE = ""
        Raspbian = "󰐿"
        Mint = "󰣭"
        Macos = "󰀵"
        Manjaro = ""
        Linux = "󰌽"
        NixOS = ""
        Gentoo = "󰣨"
        Fedora = "󰣛"
        Alpine = ""
        Amazon = ""
        Android = ""
        AOSC = ""
        Arch = "󰣇"
        Artix = "󰣇"
        EndeavourOS = ""
        CentOS = ""
        Debian = "󰣚"
        Redhat = "󱄛"
        RedHatEnterprise = "󱄛"
        Pop = ""

        [character]
        success_symbol = "[❯](bold {{colors.primary.default.hex}})"
        error_symbol = "[❯](bold {{colors.primary.default.hex}})"
      '';
    };
}
