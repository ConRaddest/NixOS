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

      xdg.desktopEntries.btop = {
        name = "btop++";
        genericName = "System Monitor";
        comment = "Resource monitor for processor, memory, disks, network and processes";
        exec = "kitty --title performance-monitor -e btop";
        icon = "btop";
        terminal = false;
        type = "Application";
        categories = [
          "System"
          "Monitor"
        ];
      };

      xdg.configFile."btop/themes/current.theme".text = ''
        theme[main_bg]="${colors.base}"
        theme[main_fg]="${colors.text}"

        theme[title]="${colors.text}"
        theme[hi_fg]="${colors.cyan}"

        theme[selected_bg]="${colors.overlay}"
        theme[selected_fg]="${colors.text}"
        theme[inactive_fg]="${colors.muted}"
        theme[proc_misc]="${colors.blue}"

        theme[cpu_box]="${colors.border}"
        theme[mem_box]="${colors.border}"
        theme[net_box]="${colors.border}"
        theme[proc_box]="${colors.border}"
        theme[div_line]="${colors.border}"

        theme[temp_start]="${colors.green}"
        theme[temp_mid]="${colors.yellow}"
        theme[temp_end]="${colors.red}"

        theme[cpu_start]="${colors.green}"
        theme[cpu_mid]="${colors.yellow}"
        theme[cpu_end]="${colors.red}"

        theme[free_start]="${colors.red}"
        theme[free_mid]="${colors.yellow}"
        theme[free_end]="${colors.green}"

        theme[cached_start]="${colors.green}"
        theme[cached_mid]="${colors.cyan}"
        theme[cached_end]="${colors.blue}"

        theme[available_start]="${colors.red}"
        theme[available_mid]="${colors.yellow}"
        theme[available_end]="${colors.green}"

        theme[used_start]="${colors.green}"
        theme[used_mid]="${colors.yellow}"
        theme[used_end]="${colors.red}"

        theme[download_start]="${colors.green}"
        theme[download_mid]="${colors.cyan}"
        theme[download_end]="${colors.blue}"

        theme[upload_start]="${colors.blue}"
        theme[upload_mid]="${colors.green}"
        theme[upload_end]="${colors.cyan}"
      '';
    };
}
