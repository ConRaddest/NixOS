{ ... }:

{
  flake.lib.homeModules.hypridle =
    { ... }:

    let
      dpmsOff = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
      dpmsOn = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            after_sleep_cmd = "${dpmsOn}";
          };

          listener = [
            {
              timeout = 300;
              on-timeout = dpmsOff;
              on-resume = dpmsOn;
            }
            {
              timeout = 600;
              on-timeout = "hyprlock";
            }
            {
              timeout = 900;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };
    };
}
