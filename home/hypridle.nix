{ ... }:

{
  flake.lib.homeModules.hypridle =
    { lib, ... }:

    let
      dpmsOff = "hyprctl dispatch dpms off";
      resume = "hyprctl dispatch dpms on; hyprctl dispatch submap reset";
    in
    {

      systemd.user.services.hypridle.Unit.ConditionEnvironment = lib.mkForce [
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP=Hyprland"
      ];

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            after_sleep_cmd = resume;
            ignore_dbus_inhibit = true;
            ignore_systemd_inhibit = true;
          };

          listener = [
            # Blank display after 5 minutes of inactivity.
            {
              timeout = 300;
              on-timeout = dpmsOff;
              on-resume = resume;
            }
            # Suspend after 15 minutes of inactivity.
            {
              timeout = 900;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };
    };
}
