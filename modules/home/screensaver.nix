{ ... }:

{
  flake.lib.homeModules.screensaver =
    {
      config,
      lib,
      pkgs,
      self,
      ...
    }:

    let
      hexDigits = "0123456789abcdef";
      hexValues = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        a = 10;
        b = 11;
        c = 12;
        d = 13;
        e = 14;
        f = 15;
      };
      hexToInt =
        value: hexValues.${builtins.substring 0 1 value} * 16 + hexValues.${builtins.substring 1 1 value};
      intToHex =
        value:
        "${builtins.substring (builtins.div value 16) 1 hexDigits}${
          builtins.substring (value - builtins.div value 16 * 16) 1 hexDigits
        }";
      mapColor =
        transform: color:
        lib.concatMapStrings intToHex [
          (transform (hexToInt (builtins.substring 0 2 color)))
          (transform (hexToInt (builtins.substring 2 2 color)))
          (transform (hexToInt (builtins.substring 4 2 color)))
        ];
      accent = lib.removePrefix "#" config.nos.theme.colors.accent;
      accentDark = mapColor (channel: builtins.floor (channel * 0.25)) accent;
      accentMedium = mapColor (channel: builtins.floor (channel * 0.55)) accent;
      accentHighlight = mapColor (channel: builtins.floor (channel + (255 - channel) * 0.75)) accent;
      screensaverRender = pkgs.writeShellApplication {
        name = "nos-screensaver-render";
        runtimeInputs = with pkgs; [
          coreutils
          procps
          terminaltexteffects
        ];
        text = ''
          stop_screensaver() {
            pkill -f '[n]os-screensaver-render' 2>/dev/null || true
          }

          trap 'exit 0' INT TERM HUP QUIT

          printf '\033]11;rgb:00/00/00\007'

          while true; do
            tte \
              -i ${self}/assets/logo.txt \
              --frame-rate 120 \
              --canvas-width 0 \
              --canvas-height 0 \
              --reuse-canvas \
              --anchor-canvas c \
              --anchor-text c \
              --no-eol \
              --no-restore-cursor \
              matrix \
              --highlight-color ${accentHighlight} \
              --rain-color-gradient ${accent} ${accentDark} \
              --rain-time 300 \
              --final-gradient-stops ${accent} ${accentMedium} &
            effect_pid=$!

            while kill -0 "$effect_pid" 2>/dev/null; do
              if read -r -n1 -t1; then
                stop_screensaver
                exit 0
              fi
            done

            wait "$effect_pid" || true
          done
        '';
      };

      cursorGuard = pkgs.writeShellApplication {
        name = "nos-screensaver-cursor-guard";
        runtimeInputs = with pkgs; [
          coreutils
          hyprland
          jq
        ];
        text = ''
          restore_cursor() {
            hyprctl eval 'hl.config({ cursor = { invisible = false } })' >/dev/null 2>&1 \
              || true
          }

          trap restore_cursor EXIT
          trap 'exit 0' INT TERM HUP QUIT

          while hyprctl clients -j 2>/dev/null \
            | jq -e 'any(.[]; .class == "nos-screensaver")' >/dev/null; do
            sleep 0.1
          done
        '';
      };

      screensaverStop = pkgs.writeShellApplication {
        name = "nos-screensaver-stop";
        runtimeInputs = with pkgs; [
          hyprland
          procps
        ];
        text = ''
          pkill -f '[n]os-screensaver-render' 2>/dev/null || true

          pkill -f '[k]itty .*--class nos-screensaver' 2>/dev/null || true

          hyprctl eval 'hl.config({ cursor = { invisible = false } })' >/dev/null 2>&1 \
            || hyprctl keyword cursor:invisible false >/dev/null 2>&1 \
            || true
        '';
      };

      screensaverLaunch = pkgs.writeShellApplication {
        name = "nos-screensaver";
        runtimeInputs = with pkgs; [
          coreutils
          hyprland
          jq
          kitty
          procps
        ];
        text = ''
          restore_cursor_without_screensaver() {
            if ! hyprctl clients -j 2>/dev/null \
              | jq -e 'any(.[]; .class == "nos-screensaver")' >/dev/null; then
              hyprctl eval 'hl.config({ cursor = { invisible = false } })' >/dev/null 2>&1 \
                || true
            fi
          }

          trap restore_cursor_without_screensaver EXIT

          if hyprctl clients -j | jq -e 'any(.[]; .class == "nos-screensaver")' >/dev/null; then
            exit 0
          fi

          focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused).name')

          pkill -f '[n]os-screensaver-cursor-guard' 2>/dev/null || true
          hyprctl eval 'hl.config({ cursor = { invisible = true } })' >/dev/null

          hypr_exec() {
            local command
            printf -v command '%q ' "$@"
            hyprctl dispatch "hl.dsp.exec_cmd([[$command]])" >/dev/null
          }

          while IFS= read -r monitor; do
            hyprctl dispatch "hl.dsp.focus({ monitor = \"$monitor\" })" >/dev/null
            previous_count=$(hyprctl clients -j | jq '[.[] | select(.class == "nos-screensaver")] | length')

            hypr_exec \
              kitty \
              --class nos-screensaver \
              --title nos-screensaver \
              --override font_size=18 \
              --override window_padding_width=0 \
              --override background=#000000 \
              --override cursor=#000000 \
              --override mouse_hide_wait=-3 \
              -e ${lib.getExe screensaverRender}

            for _ in $(seq 1 100); do
              current_count=$(hyprctl clients -j | jq '[.[] | select(.class == "nos-screensaver")] | length')
              (( current_count > previous_count )) && break
              sleep 0.05
            done
          done < <(hyprctl monitors -j | jq -r '.[].name')

          if [[ -n "$focused" ]]; then
            hyprctl dispatch "hl.dsp.focus({ monitor = \"$focused\" })" >/dev/null
          fi

          nohup ${lib.getExe cursorGuard} </dev/null >/dev/null 2>&1 &
        '';
      };
    in
    {
      home.packages = [
        screensaverLaunch
        screensaverRender
        screensaverStop
      ];

      services.hypridle = {
        enable = true;
        settings = {
          general.ignore_dbus_inhibit = false;
          listener = [
            {
              timeout = 150;
              on-timeout = lib.getExe screensaverLaunch;
              on-resume = lib.getExe screensaverStop;
            }
          ];
        };
      };
    };
}
