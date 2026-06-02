{ ... }:

{
  flake.lib.homeModules.hypridle =
    { ... }:

    let
      dpmsOff = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
      dpmsOn = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
      dpmsOnAfterResume = "sleep 2 && ${dpmsOn}";
      lock = "pgrep -x hyprlock >/dev/null || hyprlock";
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            # Do not start a second hyprlock if the session is already locked.
            # Duplicate lock instances around suspend/resume have caused
            # hyprlock crashes and Hyprland's error overlay on this machine.
            lock_cmd = lock;
            before_sleep_cmd = lock;
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
