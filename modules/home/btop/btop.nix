{ ... }:

{
  flake.lib.homeModules.btop =
    { config, ... }:

    let
      colors = config.nos.theme.colors;
    in
    {
      stylix.targets.btop.enable = false;

      programs.btop = {
        enable = true;
        settings = fromTOML (builtins.readFile ./btop.conf);
      };

      xdg.configFile."btop/themes/current.theme".text = ''
        theme[main_bg]="${colors.background}"
        theme[main_fg]="${colors.foreground}"
        theme[title]="${colors.foreground}"
        theme[hi_fg]="${colors.cyan}"
        theme[selected_bg]="${colors.selection}"
        theme[selected_fg]="${colors.cyan}"
        theme[inactive_fg]="${colors.muted}"
        theme[graph_text]="${colors.light_foreground}"
        theme[meter_bg]="${colors.selection}"
        theme[proc_misc]="${colors.light_foreground}"
        theme[cpu_box]="${colors.blue}"
        theme[mem_box]="${colors.blue}"
        theme[net_box]="${colors.blue}"
        theme[proc_box]="${colors.blue}"
        theme[div_line]="${colors.muted}"
        theme[temp_start]="${colors.green}"
        theme[temp_mid]="${colors.yellow}"
        theme[temp_end]="${colors.red}"
        theme[cpu_start]="${colors.cyan}"
        theme[cpu_mid]="${colors.blue}"
        theme[cpu_end]="${colors.magenta}"
        theme[free_start]="${colors.magenta}"
        theme[free_mid]="${colors.blue}"
        theme[free_end]="${colors.cyan}"
        theme[cached_start]="${colors.blue}"
        theme[cached_mid]="${colors.cyan}"
        theme[cached_end]="${colors.magenta}"
        theme[available_start]="${colors.yellow}"
        theme[available_mid]="${colors.red}"
        theme[available_end]="${colors.red}"
        theme[used_start]="${colors.green}"
        theme[used_mid]="${colors.cyan}"
        theme[used_end]="${colors.blue}"
        theme[download_start]="${colors.yellow}"
        theme[download_mid]="${colors.red}"
        theme[download_end]="${colors.red}"
        theme[upload_start]="${colors.green}"
        theme[upload_mid]="${colors.cyan}"
        theme[upload_end]="${colors.blue}"
        theme[process_start]="${colors.cyan}"
        theme[process_mid]="${colors.blue}"
        theme[process_end]="${colors.magenta}"
        theme[gradient_color_0]="${colors.background}"
        theme[gradient_color_1]="${colors.lighter_background}"
        theme[gradient_color_2]="${colors.selection}"
        theme[gradient_color_3]="${colors.muted}"
        theme[gradient_color_4]="${colors.dark_foreground}"
        theme[gradient_color_5]="${colors.foreground}"
        theme[gradient_color_6]="${colors.light_foreground}"
        theme[gradient_color_7]="${colors.bright_foreground}"
      '';

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
    };
}
