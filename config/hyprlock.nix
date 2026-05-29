{ colors, ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };
      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          size = "300, 50";
          position = "0, -80";
          halign = "center";
          valign = "center";
          outer_color = "rgb(${builtins.substring 1 6 colors.bgAlt})";
          inner_color = "rgb(${builtins.substring 1 6 colors.bg})";
          font_color = "rgb(${builtins.substring 1 6 colors.fg})";
          check_color = "rgb(${builtins.substring 1 6 colors.blue})";
          fail_color = "rgb(${builtins.substring 1 6 colors.red})";
          capslock_color = "rgb(${builtins.substring 1 6 colors.yellow})";
        }
      ];
    };
  };
}
