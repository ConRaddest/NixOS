{ ... }:

{
  flake.lib.homeModules.hypridle =
    { pkgs, ... }:

    let
      dpmsOff = "hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = \"disable\" }))'";
      dpmsOn = "hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = \"enable\" }))'";

      nos-lock = pkgs.writeShellScriptBin "nos-lock" ''
        set -euo pipefail

        # Never start a second hyprlock. Multiple lockers competing for the
        # session-lock protocol are a common cause of broken/black unlocks.
        if pgrep -u "$UID" -x hyprlock >/dev/null; then
          exit 0
        fi

        ${dpmsOn} >/dev/null 2>&1 || true
        hyprlock --immediate-render --no-fade-in >/tmp/hyprlock-$UID.log 2>&1 &
      '';

      nos-resume = pkgs.writeShellScriptBin "nos-resume" ''
        set -euo pipefail

        # Always bring outputs back before the locker redraws after resume.
        ${dpmsOn} >/dev/null 2>&1 || true
        hyprctl dispatch submap reset >/dev/null 2>&1 || true
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

      nos-locked-dpms-off = pkgs.writeShellScriptBin "nos-locked-dpms-off" ''
        set -euo pipefail

        if pgrep -u "$UID" -x hyprlock >/dev/null; then
          ${dpmsOff} >/dev/null 2>&1 || true
        fi
      '';

      nos-locked-suspend = pkgs.writeShellScriptBin "nos-locked-suspend" ''
        set -euo pipefail

        if pgrep -u "$UID" -x hyprlock >/dev/null; then
          ${nos-suspend}/bin/nos-suspend
        fi
      '';
    in
    {
      home.packages = [
        nos-lock
        nos-resume
        nos-suspend
        nos-locked-dpms-off
        nos-locked-suspend
      ];

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "${nos-lock}/bin/nos-lock";
            before_sleep_cmd = "${nos-lock}/bin/nos-lock";
            after_sleep_cmd = "${nos-resume}/bin/nos-resume";
          };

          listener = [
            # Once locked, blank the display after only 60 seconds of inactivity.
            # When unlocked, this listener is a no-op and the normal 300s DPMS
            # timeout below still applies.
            {
              timeout = 60;
              on-timeout = "${nos-locked-dpms-off}/bin/nos-locked-dpms-off";
              on-resume = "${nos-resume}/bin/nos-resume";
            }
            {
              timeout = 300;
              on-timeout = dpmsOff;
              on-resume = "${nos-resume}/bin/nos-resume";
            }
            # If the session is already locked, suspend after 300 seconds of
            # locked inactivity. If the lock was triggered by the normal 600s
            # idle timeout, the 900s listener below provides the same 300s delay.
            {
              timeout = 300;
              on-timeout = "${nos-locked-suspend}/bin/nos-locked-suspend";
            }
            {
              timeout = 600;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 900;
              on-timeout = "${nos-suspend}/bin/nos-suspend";
            }
          ];
        };
      };
    };
}
