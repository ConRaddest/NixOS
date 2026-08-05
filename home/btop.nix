{ ... }:

{
  flake.lib.homeModules.btop =
    { ... }:

    {
      programs.btop = {
        enable = true;
        settings = {
          color_theme = "dms";
          rounded_corners = true;
          theme_background = false;
        };
      };

      xdg.configFile."matugen/templates/btop.theme".text = ''
        theme[main_bg]=""
        theme[main_fg]="{{colors.on_surface.default.hex}}"
        theme[title]="{{colors.primary.default.hex}}"
        theme[hi_fg]="{{colors.primary.default.hex}}"
        theme[selected_bg]="{{colors.primary.default.hex}}"
        theme[selected_fg]="{{colors.on_primary.default.hex}}"
        theme[inactive_fg]="{{colors.outline.default.hex}}"
        theme[graph_text]="{{colors.on_surface_variant.default.hex}}"
        theme[meter_bg]="{{colors.surface_container_highest.default.hex}}"
        theme[proc_misc]="{{colors.secondary.default.hex}}"
        theme[cpu_box]="{{colors.primary.default.hex}}"
        theme[mem_box]="{{colors.secondary.default.hex}}"
        theme[net_box]="{{colors.tertiary.default.hex}}"
        theme[proc_box]="{{colors.primary.default.hex}}"
        theme[div_line]="{{colors.outline.default.hex}}"
        theme[temp_start]="{{colors.secondary.default.hex}}"
        theme[temp_mid]="{{dank16.color3.default.hex}}"
        theme[temp_end]="{{colors.error.default.hex}}"
        theme[cpu_start]="{{colors.primary.default.hex}}"
        theme[cpu_mid]="{{colors.secondary.default.hex}}"
        theme[cpu_end]="{{colors.on_surface_variant.default.hex}}"
        theme[free_start]="{{colors.on_surface_variant.default.hex}}"
        theme[free_mid]="{{colors.secondary.default.hex}}"
        theme[free_end]="{{colors.primary.default.hex}}"
        theme[cached_start]="{{colors.outline.default.hex}}"
        theme[cached_mid]="{{colors.on_surface_variant.default.hex}}"
        theme[cached_end]="{{colors.secondary.default.hex}}"
        theme[available_start]="{{colors.primary.default.hex}}"
        theme[available_mid]="{{colors.secondary.default.hex}}"
        theme[available_end]="{{colors.on_surface_variant.default.hex}}"
        theme[used_start]="{{colors.primary_container.default.hex}}"
        theme[used_mid]="{{colors.primary.default.hex}}"
        theme[used_end]="{{colors.secondary.default.hex}}"
        theme[download_start]="{{colors.primary.default.hex}}"
        theme[download_mid]="{{colors.secondary.default.hex}}"
        theme[download_end]="{{colors.on_surface_variant.default.hex}}"
        theme[upload_start]="{{colors.secondary.default.hex}}"
        theme[upload_mid]="{{colors.primary.default.hex}}"
        theme[upload_end]="{{colors.on_surface_variant.default.hex}}"
        theme[process_start]="{{colors.primary.default.hex}}"
        theme[process_mid]="{{colors.on_surface_variant.default.hex}}"
        theme[process_end]="{{colors.outline.default.hex}}"
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
