{ ... }:

{
  flake.lib.homeModules.hypridle =
    { ... }:

    let
      dpmsOff = "hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = \"disable\" }))'";
      dpmsOn = "hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = \"enable\" }))'";
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "hyprlock";
            before_sleep_cmd = "hyprlock";
            after_sleep_cmd = dpmsOn;
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
          ];
        };
      };
    };
}
