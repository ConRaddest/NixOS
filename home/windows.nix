{ ... }:

{
  flake.lib.homeModules.windows =
    {
      self,
      pkgs,
      flakeDirectory,
      ...
    }:

    let
      nosDir = flakeDirectory;
      envFile = "${nosDir}/.env";

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

      windows-vm-start = pkgs.writeShellScriptBin "windows-vm-start" ''
        set -euo pipefail

        container="Windows"
        compose_file="''${HOME}/.config/windows/docker-compose.yaml"
        env_file=${pkgs.lib.escapeShellArg envFile}

        if [[ -f "$env_file" ]]; then
          # shellcheck disable=SC1090
          source "$env_file"
        fi

        printf '\033[1;36mStarting Windows VM...\033[0m\n\n'
        echo "Starting Windows container..."
        docker rm -f "$container" >/dev/null 2>&1 || true
        docker compose --progress quiet --file "$compose_file" up -d >/dev/null

        echo "Waiting for windows..."
        ready=false
        for i in $(seq 1 300); do
          if timeout 1 bash -c '</dev/tcp/127.0.0.1/3389' 2>/dev/null; then
            ready=true
            break
          fi
          printf "\r  %3ds elapsed..." "$i"
          sleep 1
        done
        printf "\r\033[K"

        if [[ "$ready" != "true" ]]; then
          echo "Timed out. Windows may still be booting — check http://localhost:8006"
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
          echo "Windows is ready, connecting..."
          sleep 3
        done
        printf "\r\033[K"

        if [[ "$connected" != "true" ]]; then
          echo "Failed to connect — check http://localhost:8006"
          exit 1
        fi

        echo "Connected successfully."
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
        shared="''${HOME}/Windows"
        env_file=${pkgs.lib.escapeShellArg envFile}
        compose_file="''${HOME}/.config/windows/docker-compose.yaml"

        set_env_var() {
          local key="$1"
          local value="$2"
          local tmp
          tmp="$(mktemp)"

          mkdir -p "$(dirname "$env_file")"
          touch "$env_file"
          chmod 600 "$env_file"
          grep -Ev "^(export[[:space:]]+)?''${key}=" "$env_file" > "$tmp" || true
          printf 'export %s=%q\n' "$key" "$value" >> "$tmp"
          cat "$tmp" > "$env_file"
          rm -f "$tmp"
        }

        if ! [[ -e /dev/kvm ]]; then
          echo "error: /dev/kvm is missing. Reboot or check that virtualization is enabled." >&2
          exit 1
        fi

        if ! [[ -f "$compose_file" ]]; then
          echo "error: missing compose file: $compose_file" >&2
          echo "Run: home-manager switch --flake ${nosDir}#" >&2
          exit 1
        fi

        echo "Windows VM install"
        echo
        echo "Modify ${nosDir}/config/windows/docker-compose.yaml to change VM settings."

        read -rp "Windows username [Docker]: " username
        username="''${username:-Docker}"
        read -rsp "Windows password: " password
        echo
        if [[ -z "$password" ]]; then
          echo "error: password cannot be empty." >&2
          exit 1
        fi

        if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
          echo "A Windows VM container already exists."
          read -rp "Remove and recreate it? This keeps files in $storage. [y/N] " recreate
          case "$recreate" in
            y|Y|yes|YES) docker rm -f "$container" >/dev/null ;;
            *) echo "Cancelled."; exit 1 ;;
          esac
        fi

        mkdir -p "$storage" "$shared"
        set_env_var WINDOWS_USERNAME "$username"
        set_env_var WINDOWS_PASSWORD "$password"
        export WINDOWS_USERNAME="$username"
        export WINDOWS_PASSWORD="$password"

        echo
        echo "Pulling latest dockurr/windows image..."
        docker pull dockurr/windows:latest

        echo
        echo "Starting Windows installer from compose file..."
        docker compose --file "$compose_file" up -d

        echo
        echo "Windows installer is starting."
        echo "Installer viewer: http://localhost:8006"
        echo "After Windows finishes installing, Apps → Windows opens the VM."
        echo
        read -rp "Press Enter to close..."
      '';

      windows-uninstall = pkgs.writeShellScriptBin "windows-uninstall" ''
        set -euo pipefail

        if [[ "''${WINDOWS_UNINSTALL_IN_TERMINAL:-0}" != "1" ]]; then
          exec kitty \
            --class windows-uninstall \
            --title windows-uninstall \
            -e bash -lc "WINDOWS_UNINSTALL_IN_TERMINAL=1 windows-uninstall; echo; read -rp 'Press Enter to close...'"
        fi

        container="Windows"
        base_dir="''${HOME}/VMs/windows"
        shared="''${HOME}/Windows"
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

        echo "Windows VM uninstall"
        echo
        echo "This will permanently remove:"
        echo "  - Docker container and image"
        echo "  - VM disk:          $base_dir"
        echo "  - Windows env vars: $env_file"
        echo "  - Shared folder:    $shared"
        echo
        read -rp "Are you sure? This cannot be undone. [y/N] " confirm
        case "$confirm" in
          y|Y|yes|YES) ;;
          *) echo "Cancelled."; exit 1 ;;
        esac

        if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
          echo "Stopping and removing container..."
          docker rm -f "$container" >/dev/null
        fi

        if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "dockurr/windows"; then
          echo "Removing Docker image..."
          docker rmi dockurr/windows:latest >/dev/null 2>&1 || true
        fi

        if [[ -d "$base_dir" ]]; then
          echo "Removing VM disk..."
          rm -rf "$base_dir"
        fi

        if [[ -f "$env_file" ]]; then
          echo "Removing Windows credentials from .env..."
          remove_env_var WINDOWS_USERNAME
          remove_env_var WINDOWS_PASSWORD
        fi

        if [[ -d "$shared" ]]; then
          echo "Removing shared folder..."
          rm -rf "$shared"
        fi

        echo
        echo "Windows VM removed."
      '';

    in
    {
      xdg.desktopEntries.windows-vm = {
        name = "Windows";
        comment = "Launch Windows virtual machine";
        exec = "kitty --class windows-vm-start --title windows-vm-start -e windows-vm-start";
        icon = "windows";
        terminal = false;
        type = "Application";
        categories = [ "System" ];
      };

      home.file = {
        ".local/share/icons/hicolor/scalable/apps/windows.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
            <path fill="#0078d4" d="M67.328 67.331h60.669V128H67.328zm-67.325 0h60.669V128H.003zM67.328 0h60.669v60.669H67.328zM.003 0h60.669v60.669H.003z"/>
          </svg>
        '';
      };

      xdg.configFile."windows/docker-compose.yaml".source = "${self}/config/windows/docker-compose.yaml";

      home.packages = with pkgs; [
        docker-compose
        freerdp
        qemu

        windows-vm-rdp
        windows-vm-start
        windows-install
        windows-uninstall
      ];
    };
}
