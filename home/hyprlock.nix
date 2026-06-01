{ ... }:

{
  flake.lib.homeModules.hyprlock =
    { config, colors, ... }:

    let
      wallpaper = "${config.xdg.stateHome}/nos/current-wallpaper";
    in
    {
      programs.hyprlock = {
        enable = true;
        settings = {
          background = [
            {
              path = wallpaper;
              blur_passes = 3;
              blur_size = 8;
            }
          ];

          label = [
            {
              text = "$TIME";
              color = "rgb(${builtins.substring 1 6 colors.fg})";
              font_family = "JetBrainsMono Nerd Font";
              font_size = 60;
              halign = "center";
              valign = "center";
              position = "0, 100";
              text_align = "center";
            }
            {
              text = ''cmd[update:60000] date +"%A, %B %d"'';
              color = "rgb(${builtins.substring 1 6 colors.fg})";
              font_family = "JetBrainsMono Nerd Font";
              font_size = 16;
              halign = "center";
              valign = "center";
              position = "0, 30";
              text_align = "center";
            }
          ];

          input-field = [
            {
              size = "300, 42";
              position = "0, -50";
              halign = "center";
              valign = "center";

              fade_on_empty = false;
              placeholder_text = "Enter password...";
              fail_text = "Try again...";

              font_family = "JetBrainsMono Nerd Font Bold";
              font_color = "rgb(${builtins.substring 1 6 colors.fgDark})";

              inner_color = "rgb(${builtins.substring 1 6 colors.bg})";
              outer_color = "rgb(${builtins.substring 1 6 colors.surfaceLight})";
              check_color = "rgb(${builtins.substring 1 6 colors.blue})";
              fail_color = "rgb(${builtins.substring 1 6 colors.red})";
              capslock_color = "rgb(${builtins.substring 1 6 colors.yellow})";

              outline_thickness = 2;
              rounding = 0;
              shadow_passes = 0;
            }
          ];
        };
      };
    };
}
