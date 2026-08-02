{ ... }:

{
  flake.lib.homeModules.hypridle =
    {
      pkgs,
      lib,
      ...
    }:

    let
      dpmsOff = "hyprctl dispatch dpms off";

      baseRuntimeInputs = [
        pkgs.coreutils
        pkgs.hyprland
        pkgs.hyprlock
        pkgs.procps
        pkgs.systemd
        pkgs.util-linux
      ];

      nos-lock-idle = pkgs.writeShellApplication {
        name = "nos-lock-idle";
        runtimeInputs = baseRuntimeInputs;
        text = builtins.readFile ../scripts/system/nos-lock-idle.sh;
      };

      nos-lock = pkgs.writeShellApplication {
        name = "nos-lock";
        runtimeInputs = baseRuntimeInputs ++ [ nos-lock-idle ];
        text = builtins.readFile ../scripts/system/nos-lock.sh;
      };

      nos-resume = pkgs.writeShellApplication {
        name = "nos-resume";
        runtimeInputs = baseRuntimeInputs ++ [ nos-lock-idle ];
        text = builtins.readFile ../scripts/system/nos-resume.sh;
      };

    in
    {
      home.packages = [
        nos-lock-idle
        nos-lock
        nos-resume
      ];

      systemd.user.services.hypridle.Unit.ConditionEnvironment = lib.mkForce [
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP=Hyprland"
      ];

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "${nos-lock}/bin/nos-lock";
            before_sleep_cmd = "${nos-lock}/bin/nos-lock";
            after_sleep_cmd = "${nos-resume}/bin/nos-resume";

            # Browsers/Electron often leave idle inhibitors behind. If respected,
            # hypridle will not blank again while hyprlock is already visible.
            ignore_dbus_inhibit = true;
            ignore_systemd_inhibit = true;
          };

          listener = [
            # Blank display after 5 minutes of inactivity.
            {
              timeout = 300;
              on-timeout = dpmsOff;
              on-resume = "${nos-resume}/bin/nos-resume";
            }
            # After 15 minutes, lock and suspend together. nos-suspend invokes
            # nos-lock before calling systemctl suspend, so the session is
            # only ever locked when the machine is going to sleep.
            {
              timeout = 900;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };
    };
}
