{ ... }:

{
  flake.lib.homeModules.hyprlock =
    { config, colors, ... }:

    let
      wallpaper = "${config.xdg.stateHome}/nos/current-wallpaper";
      hex = color: builtins.substring 1 6 color;
      rgb = color: "rgb(${hex color})";
      rgba = color: alpha: "rgba(${hex color}${alpha})";
    in
    {
      programs.hyprlock = {
        enable = true;
        settings = {
          background = [
            {
              path = wallpaper;
              blur_passes = 4;
              blur_size = 7;
              brightness = 0.78;
              contrast = 0.95;
              vibrancy = 0.18;
              vibrancy_darkness = 0.15;
            }
          ];

          label = [
            {
              text = "$TIME";
              color = rgb colors.fg;
              font_family = "JetBrainsMono Nerd Font ExtraBold";
              font_size = 70;
              halign = "center";
              valign = "center";
              position = "0, 100";
              text_align = "center";
            }
            {
              text = ''cmd[update:60000] date +"%A, %B %d"'';
              color = rgb colors.fg;
              font_family = "JetBrainsMono Nerd Font Medium";
              font_size = 18;
              halign = "center";
              valign = "center";
              position = "0, 20";
              text_align = "center";
            }
          ];

          input-field = [
            {
              size = "280, 44";
              position = "0, -58";
              halign = "center";
              valign = "center";

              fade_on_empty = false;
              placeholder_text = "󰌾  Password";
              fail_text = "󰅙  Try again";

              font_family = "JetBrainsMono Nerd Font Medium";
              font_color = rgb colors.fg;

              inner_color = rgba colors.bg "88";
              check_color = rgba colors.bg "A0";
              fail_color = rgba colors.bg "88";

              outline_thickness = 0;
              rounding = -1;
            }
          ];
        };
      };
    };
}
