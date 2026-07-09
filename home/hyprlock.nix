{ ... }:

{
  flake.lib.homeModules.hyprlock =
    {
      config,
      colors,
      font,
      ...
    }:

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
              text = ''cmd[update:1000] date +"%H:%M"'';
              color = rgb colors.text;
              font_family = font.system;
              font_size = 70;
              halign = "center";
              valign = "center";
              position = "0, 100";
              text_align = "center";
            }
            {
              text = ''cmd[update:60000] date +"%A, %B %d"'';
              color = rgb colors.text;
              font_family = font.system;
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

              font_family = font.mono;
              font_color = rgb colors.text;

              inner_color = rgba colors.base "88";
              check_color = rgba colors.base "A0";
              fail_color = rgba colors.base "88";

              outline_thickness = 0;
              rounding = -1;
            }
          ];
        };
      };
    };
}
