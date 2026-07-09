{ ... }:

{
  flake.lib.homeModules.hypridle =
    { pkgs, ... }:

    let
      dpmsOff = "hyprctl dispatch dpms off";
      dpmsOn = "hyprctl dispatch dpms on";

      nos-lock-idle = pkgs.writeShellScriptBin "nos-lock-idle" ''
        set -euo pipefail

        exec 9>"/tmp/nos-lock-idle-$UID.lock"
        flock -n 9 || exit 0

        # Fallback for locked-session idle. Some hypridle versions stop
        # re-arming listeners after resume while ext-session-lock is active.
        # If the user unlocks, hyprlock exits and this watcher becomes inert.
        sleep 300
        pgrep -u "$UID" -x hyprlock >/dev/null || exit 0
        ${dpmsOff} >/dev/null 2>&1 || true

        sleep 600
        pgrep -u "$UID" -x hyprlock >/dev/null || exit 0
        systemctl suspend
      '';

      nos-lock = pkgs.writeShellScriptBin "nos-lock" ''
        set -euo pipefail

        # Never start a second hyprlock. Multiple lockers competing for the
        # session-lock protocol are a common cause of broken/black unlocks.
        if pgrep -u "$UID" -x hyprlock >/dev/null; then
          ${nos-lock-idle}/bin/nos-lock-idle >/dev/null 2>&1 &
          exit 0
        fi

        ${dpmsOn} >/dev/null 2>&1 || true
        hyprlock --immediate-render --no-fade-in >/tmp/hyprlock-$UID.log 2>&1 &
        ${nos-lock-idle}/bin/nos-lock-idle >/dev/null 2>&1 &
      '';

      nos-resume = pkgs.writeShellScriptBin "nos-resume" ''
        set -euo pipefail

        # Always bring outputs back before the locker redraws after resume.
        ${dpmsOn} >/dev/null 2>&1 || true
        hyprctl dispatch submap reset >/dev/null 2>&1 || true

        if pgrep -u "$UID" -x hyprlock >/dev/null; then
          ${nos-lock-idle}/bin/nos-lock-idle >/dev/null 2>&1 &
        fi
      '';

      nos-suspend = pkgs.writeShellScriptBin "nos-suspend" ''
        set -euo pipefail

        exec 9>"/tmp/nos-suspend-$UID.lock"
        flock -n 9 || exit 0

        ${nos-lock}/bin/nos-lock

        # Give hyprlock a short, deterministic window to bind the lock surface
        # before systemd freezes userspace. This avoids the lock/suspend race.
        for _ in $(seq 1 30); do
          pgrep -u "$UID" -x hyprlock >/dev/null && break
          sleep 0.1
        done
        sleep 0.25

        systemctl suspend
      '';

    in
    {
      home.packages = [
        nos-lock-idle
        nos-lock
        nos-resume
        nos-suspend
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
              on-timeout = "${nos-suspend}/bin/nos-suspend";
            }
          ];
        };
      };
    };
}
