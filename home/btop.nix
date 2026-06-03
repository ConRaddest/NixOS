{ ... }:

{
  flake.lib.homeModules.btop =
    { colors, ... }:

    {
      programs.btop = {
        enable = true;
        settings = {
          color_theme = "current";
          vim_keys = true;
        };
      };

      xdg.configFile."btop/themes/current.theme".text = ''
        theme[main_bg]="${colors.bg}"
        theme[main_fg]="${colors.fg}"

        theme[title]="${colors.fg}"
        theme[hi_fg]="${colors.primary}"

        theme[selected_bg]="${colors.bgLight}"
        theme[selected_fg]="${colors.fg}"
        theme[inactive_fg]="${colors.fgDark}"
        theme[proc_misc]="${colors.tertiary}"

        theme[cpu_box]="${colors.fgDark}"
        theme[mem_box]="${colors.fgDark}"
        theme[net_box]="${colors.fgDark}"
        theme[proc_box]="${colors.fgDark}"
        theme[div_line]="${colors.fgDark}"

        theme[temp_start]="${colors.green}"
        theme[temp_mid]="${colors.yellow}"
        theme[temp_end]="${colors.red}"

        theme[cpu_start]="${colors.primary}"
        theme[cpu_mid]="${colors.yellow}"
        theme[cpu_end]="${colors.red}"

        theme[free_start]="${colors.green}"
        theme[free_mid]="${colors.yellow}"
        theme[free_end]="${colors.red}"

        theme[cached_start]="${colors.green}"
        theme[cached_mid]="${colors.yellow}"
        theme[cached_end]="${colors.red}"

        theme[available_start]="${colors.green}"
        theme[available_mid]="${colors.yellow}"
        theme[available_end]="${colors.red}"

        theme[used_start]="${colors.green}"
        theme[used_mid]="${colors.yellow}"
        theme[used_end]="${colors.red}"

        theme[download_start]="${colors.green}"
        theme[download_mid]="${colors.yellow}"
        theme[download_end]="${colors.red}"

        theme[upload_start]="${colors.green}"
        theme[upload_mid]="${colors.yellow}"
        theme[upload_end]="${colors.red}"
      '';
    };
}
