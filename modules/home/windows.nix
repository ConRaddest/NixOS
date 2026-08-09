{ ... }:

{
  flake.lib.homeModules.windows =
    {
      config,
      host,
      pkgs,
      ...
    }:

    let
      mutableConfigDir =
        if config.nos.flakeDirectory != null then
          config.nos.flakeDirectory
        else
          "${config.xdg.configHome}/nos";
      envFile = "${mutableConfigDir}/.env";

      windows-vm-rdp = pkgs.writeShellScriptBin "windows-vm-rdp" ''
        set -euo pipefail

        viewer_class="windows-vm"
        env_file=${pkgs.lib.escapeShellArg envFile}
        log_file="''${HOME}/.local/state/windows-vm.log"

        mode="foreground"
        if [[ "''${1:-}" == "--background" ]]; then
          mode="background"
          shift
        fi

        if [[ -f "$env_file" ]]; then
          # shellcheck disable=SC1090
          source "$env_file"
        fi

        user="''${1:-''${WINDOWS_USERNAME:-Docker}}"
        pass="''${WINDOWS_PASSWORD:-}"
        args_file="$(mktemp --tmpdir windows-vm-rdp.XXXXXX)"
        chmod 600 "$args_file"

        cleanup() {
          rm -f "$args_file"
        }

        write_rdp_args() {
          {
            printf '%s\n' "/v:127.0.0.1:3389"
            printf '%s\n' "/u:$user"
            [[ -n "$pass" ]] && printf '%s\n' "/p:$pass"
            printf '%s\n' "/dynamic-resolution"
            printf '%s\n' "/clipboard"
            printf '%s\n' "+home-drive"
            printf '%s\n' "-grab-keyboard"
            printf '%s\n' "/cert:ignore"
            printf '%s\n' "/network:auto"
            printf '%s\n' "/scale:100"
            printf '%s\n' "+rfx"
            printf '%s\n' "/gfx:progressive"
            printf '%s\n' "/wm-class:$viewer_class"
            printf '%s\n' "/t:Windows"
          } > "$args_file"
        }

        rdp_command() {
          if command -v xfreerdp3 >/dev/null 2>&1; then
            printf '%s\n' "xfreerdp3"
          else
            printf '%s\n' "xfreerdp"
          fi
        }

        write_rdp_args
        rdp_bin="$(rdp_command)"

        case "$mode" in
          foreground)
            trap cleanup EXIT
            exec "$rdp_bin" /args-from:file:"$args_file"
            ;;
          background)
            mkdir -p "$(dirname "$log_file")"
            : > "$log_file"
            "$rdp_bin" /args-from:file:"$args_file" >>"$log_file" 2>&1 &
            (sleep 5; cleanup) >/dev/null 2>&1 &
            ;;
          *)
            echo "usage: windows-vm-rdp [--background] [username]" >&2
            cleanup
            exit 2
            ;;
        esac
      '';

      windows-vm-app = pkgs.writeShellScriptBin "windows-vm-app" ''
        set -euo pipefail

        app="''${1:-C:\\Windows\\System32\\notepad.exe}"
        app_args="''${2:-}"
        compose_file="''${HOME}/.config/windows/docker-compose.yaml"
        env_file=${pkgs.lib.escapeShellArg envFile}

        if [[ -f "$env_file" ]]; then
          # shellcheck disable=SC1090
          source "$env_file"
        fi

        user="''${WINDOWS_USERNAME:-Docker}"
        pass="''${WINDOWS_PASSWORD:-}"
        if [[ -z "$pass" ]]; then
          echo "Windows password missing; run windows-install first." >&2
          exit 1
        fi

        notify() {
          ${pkgs.libnotify}/bin/notify-send \
            --app-name="Windows Apps" \
            --icon="windows" \
            "''${@}" || true
        }

        vm_was_running=false
        if docker ps --format '{{.Names}}' | grep -qx Windows; then
          vm_was_running=true
        else
          notify \
            "Starting Windows VM" \
            "This app may take 1–3 minutes to launch."
        fi

        if [[ "$(docker inspect --format '{{.State.Paused}}' Windows 2>/dev/null || true)" == "true" ]]; then
          docker unpause Windows >/dev/null
        fi

        if ! docker compose --progress quiet --file "$compose_file" up -d >/dev/null; then
          notify --urgency=critical "Windows app failed" "Could not start Windows VM."
          exit 1
        fi

        rdp_ready=false
        for _ in $(seq 1 300); do
          if timeout 1 bash -c '</dev/tcp/127.0.0.1/3389' 2>/dev/null; then
            rdp_ready=true
            break
          fi
          sleep 1
        done
        if [[ "$rdp_ready" != "true" ]]; then
          notify --urgency=critical "Windows app failed" "Timed out waiting for Windows RDP."
          exit 1
        fi

        # Port 3389 opens before Windows finishes startup and releases its
        # temporary console session. Connecting immediately exposes the full
        # Windows sign-in screen instead of a RemoteApp surface.
        if [[ "$vm_was_running" == "false" ]]; then
          sleep 20
        fi

        if command -v xfreerdp3 >/dev/null 2>&1; then
          rdp_bin="xfreerdp3"
        else
          rdp_bin="xfreerdp"
        fi

        launch_remote_app() {
          # Feed arguments through stdin so password never appears in process
          # list or persists in a temporary file.
          {
            printf '%s\n' "/v:127.0.0.1:3389"
            printf '%s\n' "/u:$user"
            printf '%s\n' "/p:$pass"
            # hidef:off prevents RAIL maximized-window geometry from being
            # interpreted as a compositor fullscreen request.
            if [[ -n "$app_args" ]]; then
              printf '%s\n' "/app:program:$app,cmd:$app_args,hidef:off"
            else
              printf '%s\n' "/app:program:$app,hidef:off"
            fi
            printf '%s\n' "/cert:tofu"
            printf '%s\n' "/auth-pkg-list:!kerberos"
            printf '%s\n' "/clipboard"
            printf '%s\n' "+home-drive"
            printf '%s\n' "/sound"
            printf '%s\n' "/network:auto"
            printf '%s\n' "/wm-class:windows-vm"
            printf '%s\n' "/log-level:ERROR"
            printf '%s\n' "/log-filters:TODO:OFF,com.winpr.sspi.Kerberos:OFF"
          } | "$rdp_bin" /args-from:stdin
        }

        # RDP port opens before Windows finishes accepting RemoteApp sessions.
        # Retry short-lived failures until one session remains connected.
        log_file="$HOME/.local/state/windows-vm-app.log"
        mkdir -p "$(dirname "$log_file")"
        for attempt in $(seq 1 30); do
          launch_remote_app >>"$log_file" 2>&1 &
          rdp_pid=$!
          sleep 8
          if kill -0 "$rdp_pid" 2>/dev/null; then
            [[ "$vm_was_running" == "false" ]] && notify "Windows app ready" "Remote application launched."
            wait "$rdp_pid"
            exit $?
          fi
          wait "$rdp_pid" 2>/dev/null || true
          sleep 2
        done

        notify \
          --urgency=critical \
          "Windows app failed" \
          "Could not establish RemoteApp session. See $log_file"
        exit 1
      '';

      windows-azure-vpn-client = pkgs.writeShellScriptBin "windows-azure-vpn-client" ''
        exec windows-vm-app \
          'C:\Windows\explorer.exe' \
          'shell:AppsFolder\Microsoft.AzureVpn_8wekyb3d8bbwe!App'
      '';

      windows-ssms = pkgs.writeShellScriptBin "windows-ssms" ''
        exec windows-vm-app \
          'C:\Windows\explorer.exe' \
          'shell:AppsFolder\SSMS.0807045d'
      '';

      windows-powershell = pkgs.writeShellScriptBin "windows-powershell" ''
        exec windows-vm-app \
          'C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe'
      '';

      windows-vm-stop = pkgs.writeShellScriptBin "windows-vm-stop" ''
        set -euo pipefail

        compose_file="''${HOME}/.config/windows/docker-compose.yaml"

        hide_remote_windows() {
          ${pkgs.hyprland}/bin/hyprctl clients -j \
            | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "windows-vm") | .address' \
            | while IFS= read -r address; do
                ${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspacesilent \
                  "special:windows-shutdown,address:$address" >/dev/null 2>&1 || true
              done
        }

        # Move existing and newly-created RAIL shutdown surfaces away before
        # Windows replaces application contents with its fullscreen shutdown UI.
        hide_remote_windows
        (
          while docker ps --format '{{.Names}}' | grep -qx Windows; do
            hide_remote_windows
            sleep 0.2
          done
        ) &
        hide_pid=$!

        cleanup() {
          kill "$hide_pid" 2>/dev/null || true
          wait "$hide_pid" 2>/dev/null || true
        }
        trap cleanup EXIT

        docker compose --file "$compose_file" stop
        cleanup
        trap - EXIT

        ${pkgs.libnotify}/bin/notify-send \
          --app-name="Windows Apps" \
          --icon="windows" \
          "Windows VM stopped"
      '';

      windows-vm-start = pkgs.writeShellScriptBin "windows-vm-start" ''
        set -euo pipefail

        compose_file="''${HOME}/.config/windows/docker-compose.yaml"
        env_file=${pkgs.lib.escapeShellArg envFile}

        if [[ -f "$env_file" ]]; then
          # shellcheck disable=SC1090
          source "$env_file"
        fi

        notify() {
          ${pkgs.libnotify}/bin/notify-send \
            --app-name="Windows" \
            --icon="windows" \
            "''${@}" || true
        }

        if ! docker ps --format '{{.Names}}' | grep -qx Windows; then
          notify \
            "Starting Windows VM" \
            "Windows may take 1–3 minutes to launch."
        fi

        if ! docker compose --progress quiet --file "$compose_file" up -d >/dev/null; then
          notify --urgency=critical "Windows failed to start" "Could not start Windows VM."
          exit 1
        fi

        ready=false
        for _ in $(seq 1 300); do
          if timeout 1 bash -c '</dev/tcp/127.0.0.1/3389' 2>/dev/null; then
            ready=true
            break
          fi
          sleep 1
        done

        if [[ "$ready" != "true" ]]; then
          notify \
            --urgency=critical \
            "Windows failed to start" \
            "Timed out waiting for RDP. Check http://localhost:8006"
          exit 1
        fi

        connected=false
        for _ in $(seq 1 30); do
          setsid windows-vm-rdp >/dev/null 2>&1 &
          rdp_pid=$!
          sleep 5
          if kill -0 "$rdp_pid" 2>/dev/null; then
            connected=true
            break
          fi
          wait "$rdp_pid" 2>/dev/null || true
          sleep 3
        done

        if [[ "$connected" != "true" ]]; then
          notify \
            --urgency=critical \
            "Windows failed to connect" \
            "Could not establish RDP session. Check http://localhost:8006"
          exit 1
        fi

        notify "Windows ready" "Remote desktop connected."
      '';

      windows-install = pkgs.writeShellScriptBin "windows-install" ''
        set -euo pipefail

        if [[ "''${WINDOWS_INSTALL_IN_TERMINAL:-0}" != "1" ]]; then
          exec kitty \
            --class windows-install \
            --title windows-install \
            -e bash -lc "WINDOWS_INSTALL_IN_TERMINAL=1 windows-install"
        fi

        container="Windows"
        base_dir="''${HOME}/VMs/windows"
        storage="''${base_dir}/storage"
        shared="''${base_dir}/shared"
        env_file=${pkgs.lib.escapeShellArg envFile}
        compose_file="''${HOME}/.config/windows/docker-compose.yaml"

        set_env_var() {
          local key="$1"
          local value="$2"
          local tmp
          tmp="$(mktemp)"

          mkdir -p "$(dirname "$env_file")"
          touch "$env_file"
          grep -Ev "^(export[[:space:]]+)?''${key}=" "$env_file" > "$tmp" || true
          printf 'export %s=%q\n' "$key" "$value" >> "$tmp"
          cat "$tmp" > "$env_file"
          rm -f "$tmp"
        }

        if ! [[ -e /dev/kvm ]]; then
          echo "error: /dev/kvm is missing. reboot or check that virtualization is enabled." >&2
          exit 1
        fi

        if ! [[ -f "$compose_file" ]]; then
          echo "error: missing compose file: $compose_file" >&2
          echo "run: home-manager switch" >&2
          exit 1
        fi

        echo "windows vm setup"
        echo
        echo "tweak $compose_file to change vm settings."

        read -rp "windows username [docker]: " username
        username="''${username:-Docker}"
        read -rsp "windows password: " password
        echo
        if [[ -z "$password" ]]; then
          echo "error: password cannot be empty." >&2
          exit 1
        fi

        if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
          echo "windows vm container already exists."
          read -rp "recreate it? files in $storage stay put. [y/n, default: n] " recreate
          case "$recreate" in
            y|Y|yes|YES) docker rm -f "$container" >/dev/null ;;
            *) echo "cancelled."; exit 1 ;;
          esac
        fi

        mkdir -p "$storage" "$shared"
        set_env_var WINDOWS_USERNAME "$username"
        set_env_var WINDOWS_PASSWORD "$password"
        export WINDOWS_USERNAME="$username"
        export WINDOWS_PASSWORD="$password"

        echo
        echo "pulling latest dockurr/windows image..."
        docker pull dockurr/windows:latest

        echo
        echo "starting windows installer from compose file..."
        docker compose --file "$compose_file" up -d

        echo
        echo "windows installer is starting."
        echo "installer: http://localhost:8006"
        echo "once windows is installed, apps → windows opens the vm."
        echo
        read -rp "press enter to close..."
      '';

      windows-uninstall = pkgs.writeShellScriptBin "windows-uninstall" ''
        set -euo pipefail

        if [[ "''${WINDOWS_UNINSTALL_IN_TERMINAL:-0}" != "1" ]]; then
          exec kitty \
            --class windows-uninstall \
            --title windows-uninstall \
            -e bash -lc "WINDOWS_UNINSTALL_IN_TERMINAL=1 windows-uninstall; echo; read -rp 'press enter to close...'"
        fi

        container="Windows"
        base_dir="''${HOME}/VMs/windows"
        env_file=${pkgs.lib.escapeShellArg envFile}

        remove_env_var() {
          local key="$1"
          local tmp
          tmp="$(mktemp)"

          if [[ -f "$env_file" ]]; then
            grep -Ev "^(export[[:space:]]+)?''${key}=" "$env_file" > "$tmp" || true
            cat "$tmp" > "$env_file"
          fi

          rm -f "$tmp"
        }

        echo "windows vm uninstall"
        echo
        echo "this permanently deletes:"
        echo "  - docker container and image"
        echo "  - vm disk and shared folder: $base_dir"
        echo "  - windows env vars:          $env_file"
        echo
        read -rp "you sure? can't undo this. [y/n, default: n] " confirm
        case "$confirm" in
          y|Y|yes|YES) ;;
          *) echo "cancelled."; exit 1 ;;
        esac

        if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
          echo "stopping and removing container..."
          docker rm -f "$container" >/dev/null
        fi

        if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "dockurr/windows"; then
          echo "removing docker image..."
          docker rmi dockurr/windows:latest >/dev/null 2>&1 || true
        fi

        if [[ -d "$base_dir" ]]; then
          echo "removing vm disk..."
          rm -rf "$base_dir"
        fi

        if [[ -f "$env_file" ]]; then
          echo "removing windows credentials from .env..."
          remove_env_var WINDOWS_USERNAME
          remove_env_var WINDOWS_PASSWORD
        fi

        echo
        echo "windows vm removed."
      '';

    in
    {
      xdg.desktopEntries = {
        windows-vm = {
          name = "Windows";
          comment = "Launch Windows virtual machine";
          exec = "windows-vm-start";
          icon = "windows";
          terminal = false;
          type = "Application";
          categories = [ "System" ];
        };

        windows-vm-stop = {
          name = "Stop Windows";
          comment = "Gracefully stop Windows virtual machine";
          exec = "windows-vm-stop";
          icon = "windows";
          terminal = false;
          type = "Application";
          categories = [ "System" ];
        };

        windows-azure-vpn-client = {
          name = "Azure VPN Client";
          comment = "Launch Azure VPN Client on Windows";
          exec = "windows-azure-vpn-client";
          icon = "azure-vpn-client";
          terminal = false;
          type = "Application";
          categories = [ "Network" ];
        };

        windows-ssms = {
          name = "SQL Server Management Studio 22";
          comment = "Launch SSMS on Windows";
          exec = "windows-ssms";
          icon = "ssms";
          terminal = false;
          type = "Application";
          categories = [ "Development" ];
        };

        windows-powershell = {
          name = "Windows PowerShell";
          comment = "Launch PowerShell on Windows";
          exec = "windows-powershell";
          icon = "windows-powershell";
          terminal = false;
          type = "Application";
          categories = [
            "Development"
            "System"
          ];
        };
      };

      home.file = {
        ".local/share/icons/hicolor/scalable/apps/windows.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
            <path fill="#0078d4" d="M67.328 67.331h60.669V128H67.328zm-67.325 0h60.669V128H.003zM67.328 0h60.669v60.669H67.328zM.003 0h60.669v60.669H.003z"/>
          </svg>
        '';

        ".local/share/icons/hicolor/scalable/apps/ssms.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
            <defs>
              <radialGradient id="b" cx="9.36" cy="10.57" fx="9.36" fy="10.57" r="7.07" gradientTransform="matrix(73.03125 0 0 37.1875 29.797 56.535)">
                <stop offset="0" style="stop-color:#f2f2f2;stop-opacity:1"/>
                <stop offset=".58" style="stop-color:#eee;stop-opacity:1"/>
                <stop offset="1" style="stop-color:#e6e6e6;stop-opacity:1"/>
              </radialGradient>
              <linearGradient id="a" gradientUnits="userSpaceOnUse" x1="2.59" y1="10.16" x2="15.41" y2="10.16" gradientTransform="scale(7.11111)">
                <stop offset="0" style="stop-color:#005ba1;stop-opacity:1"/>
                <stop offset=".07" style="stop-color:#0060a9;stop-opacity:1"/>
                <stop offset=".36" style="stop-color:#0071c8;stop-opacity:1"/>
                <stop offset=".52" style="stop-color:#0078d4;stop-opacity:1"/>
                <stop offset=".64" style="stop-color:#0074cd;stop-opacity:1"/>
                <stop offset=".82" style="stop-color:#006abb;stop-opacity:1"/>
                <stop offset="1" style="stop-color:#005ba1;stop-opacity:1"/>
              </linearGradient>
            </defs>
            <path style="stroke:none;fill-rule:nonzero;fill:url(#a)" d="M64 36.55c-25.172 0-45.582-7.109-45.582-16.495v87.89c0 9.032 20.055 16.356 44.941 16.5H64c25.172 0 45.582-7.113 45.582-16.5v-87.89c0 9.172-20.41 16.496-45.582 16.496Zm0 0"/>
            <path style="stroke:none;fill-rule:nonzero;fill:#e8e8e8;fill-opacity:1" d="M109.582 20.055c0 9.172-20.41 16.496-45.582 16.496s-45.582-7.11-45.582-16.496c0-9.387 20.41-16.5 45.582-16.5s45.582 7.113 45.582 16.5"/>
            <path style="stroke:none;fill-rule:nonzero;fill:#50e6ff;fill-opacity:1" d="M98.988 18.703c0 5.832-15.718 10.524-34.988 10.524s-34.988-4.692-34.988-10.524C29.012 12.871 44.73 8.25 64 8.25s34.988 4.691 34.988 10.453"/>
            <path style="stroke:none;fill-rule:nonzero;fill:#198ab3;fill-opacity:1" d="M64 21.332a82.193 82.193 0 0 0-27.664 4.055A81.213 81.213 0 0 0 64 29.227a79.334 79.334 0 0 0 27.664-4.125A84.332 84.332 0 0 0 64 21.332Zm0 0"/>
            <path style="stroke:none;fill-rule:nonzero;fill:url(#b)" d="M91.734 81.066V56.891h-6.402v29.367h17.496v-5.192ZM40.961 69.191a13.064 13.064 0 0 1-3.629-2.203 3.13 3.13 0 0 1-.852-2.277 2.418 2.418 0 0 1 1.067-2.133 4.847 4.847 0 0 1 2.988-.855 11.533 11.533 0 0 1 7.11 2.062v-6.113a18.236 18.236 0 0 0-7.11-1.137 11.67 11.67 0 0 0-7.754 2.414 7.68 7.68 0 0 0-2.984 6.332c0 3.625 2.273 6.469 7.11 8.602 1.57.668 3.05 1.527 4.41 2.562a2.982 2.982 0 0 1 1.066 2.274c0 .879-.426 1.699-1.137 2.207a5.786 5.786 0 0 1-3.203.781 11.801 11.801 0 0 1-7.75-2.988v6.613a15.411 15.411 0 0 0 7.61 1.707c2.98.176 5.933-.648 8.39-2.348a7.681 7.681 0 0 0 2.348-6.468 7.458 7.458 0 0 0-1.778-4.977 17.225 17.225 0 0 0-5.902-4.055Zm37.262 11.305a16.634 16.634 0 0 0 2.347-8.957A16.509 16.509 0 0 0 78.223 64a12.87 12.87 0 0 0-4.977-5.332 14.228 14.228 0 0 0-7.113-1.852 15.015 15.015 0 0 0-7.68 1.922A13.217 13.217 0 0 0 53.262 64a17.48 17.48 0 0 0-1.848 8.105 16.06 16.06 0 0 0 1.707 7.114 12.526 12.526 0 0 0 4.906 5.261 14.679 14.679 0 0 0 7.11 2.133l6.117 7.11h8.605l-8.75-7.82a12.736 12.736 0 0 0 7.114-5.407Zm-7.114-1.777a6.673 6.673 0 0 1-5.402 2.488 6.538 6.538 0 0 1-5.406-2.559 10.842 10.842 0 0 1-2.063-7.109 10.903 10.903 0 0 1 2.063-7.113 7.104 7.104 0 0 1 5.547-2.63 6.181 6.181 0 0 1 5.336 2.63 11.533 11.533 0 0 1 1.918 7.113 10.353 10.353 0 0 1-1.993 7.18Zm0 0"/>
          </svg>
        '';

        ".local/share/icons/hicolor/scalable/apps/azure-vpn-client.svg".text = ''
          <svg viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <linearGradient id="azure-original-a" x1="60.919" y1="9.602" x2="18.667" y2="134.423" gradientUnits="userSpaceOnUse"><stop stop-color="#114A8B"/><stop offset="1" stop-color="#0669BC"/></linearGradient>
              <linearGradient id="azure-original-b" x1="74.117" y1="67.772" x2="64.344" y2="71.076" gradientUnits="userSpaceOnUse"><stop stop-opacity=".3"/><stop offset=".071" stop-opacity=".2"/><stop offset=".321" stop-opacity=".1"/><stop offset=".623" stop-opacity=".05"/><stop offset="1" stop-opacity="0"/></linearGradient>
              <linearGradient id="azure-original-c" x1="68.742" y1="5.961" x2="115.122" y2="129.525" gradientUnits="userSpaceOnUse"><stop stop-color="#3CCBF4"/><stop offset="1" stop-color="#2892DF"/></linearGradient>
            </defs>
            <path d="M46.09.002h40.685L44.541 125.137a6.485 6.485 0 01-6.146 4.413H6.733a6.482 6.482 0 01-5.262-2.699 6.474 6.474 0 01-.876-5.848L39.944 4.414A6.488 6.488 0 0146.09 0z" fill="url(#azure-original-a)" transform="translate(.587 4.468) scale(.91904)"/>
            <path d="M97.28 81.607H37.987a2.743 2.743 0 00-1.874 4.751l38.1 35.562a5.991 5.991 0 004.087 1.61h33.574z" fill="#0078d4"/>
            <path d="M46.09.002A6.434 6.434 0 0039.93 4.5L.644 120.897a6.469 6.469 0 006.106 8.653h32.48a6.942 6.942 0 005.328-4.531l7.834-23.089 27.985 26.101a6.618 6.618 0 004.165 1.519h36.396l-15.963-45.616-46.533.011L86.922.002z" fill="url(#azure-original-b)" transform="translate(.587 4.468) scale(.91904)"/>
            <path d="M98.055 4.408A6.476 6.476 0 0091.917.002H46.575a6.478 6.478 0 016.137 4.406l39.35 116.594a6.476 6.476 0 01-6.137 8.55h45.344a6.48 6.48 0 006.136-8.55z" fill="url(#azure-original-c)" transform="translate(.587 4.468) scale(.91904)"/>
          </svg>
        '';

        ".local/share/icons/hicolor/scalable/apps/windows-powershell.svg".text = ''
          <svg height="1887" viewBox="-2.186 -.046 208.897 154.612" width="2500" xmlns="http://www.w3.org/2000/svg">
            <g clip-rule="evenodd" fill-rule="evenodd">
              <path d="m120.14.032c23.011-.008 46.023-.078 69.034.019 13.68.056 17.537 4.627 14.588 18.137-8.636 39.566-17.466 79.092-26.415 118.589-2.83 12.484-9.332 17.598-22.465 17.637-46.023.137-92.046.152-138.068-.006-15.043-.053-19-5.148-15.759-19.404a39065.945 39065.945 0 0 1 26.547-116.112c3.395-14.744 8.497-18.792 23.502-18.835 23.012-.065 46.024-.017 69.036-.025z" fill="#e0eaf5"/>
              <path d="m85.365 149.813c-23.014-.008-46.029.098-69.042-.053-11.67-.076-13.792-2.83-11.165-14.244 8.906-38.71 18.099-77.355 26.807-116.109 2.335-10.394 7.372-14.988 18.508-14.885 46.024.427 92.056.137 138.083.184 11.543.011 13.481 2.48 10.89 14.187-8.413 38.007-16.879 76.003-25.494 113.965-3.224 14.207-6.938 16.918-21.885 16.951-22.234.047-44.469.012-66.702.004z" fill="#2671be"/>
              <path d="m104.948 73.951c-1.543-1.81-3.237-3.894-5.031-5.886-10.173-11.3-20.256-22.684-30.61-33.815-4.738-5.094-6.248-10.041-.558-15.069 5.623-4.97 11.148-4.53 16.306 1.188 14.365 15.919 28.713 31.856 43.316 47.556 5.452 5.864 4.182 9.851-1.823 14.196-23.049 16.683-45.968 33.547-68.862 50.443-5.146 3.799-10.052 4.75-14.209-.861-4.586-6.189-.343-9.871 4.414-13.335 17.013-12.392 33.993-24.83 50.9-37.366 2.355-1.746 5.736-2.764 6.157-7.051z" fill="#fdfdfe"/>
              <path d="m112.235 133.819c-6.196 0-12.401.213-18.583-.068-4.932-.223-7.9-2.979-7.838-8.174.06-4.912 2.536-8.605 7.463-8.738 13.542-.363 27.104-.285 40.651-.02 4.305.084 7.483 2.889 7.457 7.375-.031 5.146-2.739 9.133-8.25 9.465-6.944.42-13.931.104-20.899.104z" fill="#fcfdfd"/>
            </g>
          </svg>
        '';
      };

      xdg.configFile."windows/enable-remote-apps.reg".text = ''
        Windows Registry Editor Version 5.00

        [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList]
        "fDisabledAllowList"=dword:00000001

        [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services]
        "fAllowUnlistedRemotePrograms"=dword:00000001

        ; Prevent Dockur's console auto-login from competing with RemoteApp RDP.
        [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
        "AutoAdminLogon"="0"
      '';

      xdg.configFile."windows/docker-compose.yaml".text = ''
        services:
          windows:
            image: dockurr/windows:latest
            container_name: Windows
            restart: "no"
            stop_grace_period: 120s

            devices:
              - /dev/kvm
              - /dev/net/tun

            cap_add:
              - NET_ADMIN

            ports:
              - "127.0.0.1:8006:8006"
              - "127.0.0.1:3389:3389/tcp"
              - "127.0.0.1:3389:3389/udp"
              - "127.0.0.1:11433:11433/tcp"

            volumes:
              - ''${HOME}/VMs/windows/storage:/storage
              - ''${HOME}/VMs/windows/shared:/shared

            environment:
              TZ: "${host.windows.timeZone}"
              VERSION: "11"
              RAM_SIZE: "${host.windows.memory}"
              CPU_CORES: "${toString host.windows.cpuCores}"
              DISK_SIZE: "${host.windows.diskSize}"
              USERNAME: ''${WINDOWS_USERNAME:-Docker}
              PASSWORD: ''${WINDOWS_PASSWORD:?Run windows-install to save WINDOWS_PASSWORD in ~/NixOS/.env}
      '';

      home.packages = with pkgs; [
        docker-compose
        freerdp
        qemu

        windows-vm-rdp
        windows-vm-app
        windows-azure-vpn-client
        windows-ssms
        windows-powershell
        windows-vm-start
        windows-vm-stop
        windows-install
        windows-uninstall
      ];

      home.activation.removeLegacyWinApps = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        for directory in "$HOME/.local/share/applications" "$HOME/.local/bin"; do
          if [[ -d "$directory" ]]; then
            while IFS= read -r file; do
              rm -f "$file"
            done < <(find "$directory" -maxdepth 1 -type f -exec grep -Il winapps {} \; 2>/dev/null)
          fi
        done
        rm -rf "$HOME/.local/share/winapps" "$HOME/.config/winapps"
      '';
    };
}
