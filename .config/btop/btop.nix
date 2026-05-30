{ colors, ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      vim_keys = true;
    };
  };

  xdg.configFile."btop/themes/tokyo-night.theme".text = ''
    theme[main_bg]="${colors.bg}"
    theme[main_fg]="${colors.fg}"
    theme[title]="${colors.fg}"
    theme[hi_fg]="${colors.blue}"
    theme[selected_bg]="${colors.bgAlt}"
    theme[selected_fg]="${colors.fg}"
    theme[inactive_fg]="${colors.comment}"
    theme[graph_text]="${colors.fgDark}"
    theme[meter_bg]="${colors.bgAlt}"
    theme[proc_misc]="${colors.comment}"
    theme[cpu_box]="${colors.bgAlt}"
    theme[mem_box]="${colors.bgAlt}"
    theme[net_box]="${colors.bgAlt}"
    theme[proc_box]="${colors.bgAlt}"
    theme[div_line]="${colors.bgAlt}"
    theme[temp_start]="${colors.teal}"
    theme[temp_mid]="${colors.yellow}"
    theme[temp_end]="${colors.red}"
    theme[cpu_start]="${colors.blue}"
    theme[cpu_mid]="${colors.magenta}"
    theme[cpu_end]="${colors.purple}"
    theme[free_start]="${colors.teal}"
    theme[free_mid]="${colors.green}"
    theme[free_end]="${colors.yellow}"
    theme[cached_start]="${colors.cyan}"
    theme[cached_mid]="${colors.blue}"
    theme[cached_end]="${colors.magenta}"
    theme[used_start]="${colors.green}"
    theme[used_mid]="${colors.yellow}"
    theme[used_end]="${colors.red}"
    theme[download_start]="${colors.cyan}"
    theme[download_mid]="${colors.blue}"
    theme[download_end]="${colors.magenta}"
    theme[upload_start]="${colors.teal}"
    theme[upload_mid]="${colors.yellow}"
    theme[upload_end]="${colors.red}"
    theme[process_start]="${colors.blue}"
    theme[process_mid]="${colors.purple}"
    theme[process_end]="${colors.magenta}"
  '';
}
