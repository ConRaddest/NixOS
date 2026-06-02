{ ... }:

{
  flake.lib.homeModules.mako =
    { colors, font, ... }:

    {
      services.mako = {
        enable = true;

        settings = {
          font = "${font.system} 11";
          width = 400;
          height = 120;
          margin = "12";
          padding = "12,16";
          border-size = 2;
          icons = false;
          default-timeout = 5000;
          ignore-timeout = true;

          background-color = colors.bg;
          text-color = colors.fg;
          border-color = colors.bgLight;
          progress-color = "over ${colors.primary}";
        };
      };
    };
}
