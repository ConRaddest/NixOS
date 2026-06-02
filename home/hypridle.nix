{ ... }:

{
  flake.lib.homeModules.hypridle =
    { ... }:

    let
      dpmsOff = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
      dpmsOn = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
      dpmsOnAfterResume = "sleep 2 && ${dpmsOn}";
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "hyprlock";
            before_sleep_cmd = "hyprlock";
            # Give NVIDIA's resume path a moment before asking Hyprland to
            # modeset/turn outputs back on. Immediate DPMS-on can race resume.
            after_sleep_cmd = dpmsOnAfterResume;
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
