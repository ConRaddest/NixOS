{ ... }:

{
  flake.lib.homeModules.hypridle =
    { ... }:

    let
      dpmsOff = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
      dpmsOn = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
      lock = "pgrep -x hyprlock >/dev/null || hyprlock";
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = lock;
            before_sleep_cmd = lock;
            after_sleep_cmd = "sleep 2 && ${dpmsOn}";
          };

          listener = [
            {
              timeout = 300;
              on-timeout = dpmsOff;
              on-resume = dpmsOn;
            }
            {
              timeout = 600;
              on-timeout = lock;
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
