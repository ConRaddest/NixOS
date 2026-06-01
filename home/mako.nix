{ ... }:

{
  flake.lib.homeModules.mako =
    { colors, font, ... }:

    {
      services.mako = {
        enable = true;

        settings = {
          font = "${font.mono} 11";
          width = 400;
          height = 120;
          margin = "12";
          padding = "12,16";
          border-size = 2;
          default-timeout = 5000;
          ignore-timeout = false;

          background-color = colors.bg;
          text-color = colors.fg;
          border-color = colors.surfaceLight;
          progress-color = "over ${colors.blue}";
        };
      };
    };
}
