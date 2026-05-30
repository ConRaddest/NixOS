{ pkgs, ... }:

let
  windowsScript = pkgs.writeShellScriptBin "windows-vm" (builtins.readFile ./scripts/windows.sh);
  windowsInstallScript = pkgs.writeShellScriptBin "windows-install" (builtins.readFile ./scripts/windows-install.sh);
in
{
  xdg.configFile."windows/docker-compose.yaml".source = ./docker-compose.yaml;

  home.packages = with pkgs; [
    docker-compose
    freerdp
    windowsScript
    windowsInstallScript

    (writeShellScriptBin "windows-vm-stop" ''
      set -euo pipefail
      docker stop Windows
    '')

    (writeShellScriptBin "windows-vm-rdp" ''
      set -euo pipefail

      config_file="''${HOME}/VMs/windows/config.env"
      if [[ -f "$config_file" ]]; then
        source "$config_file"
      fi

      user="''${1:-''${USERNAME:-cdt}}"
      pass="''${PASSWORD:-}"
      args_file="$(mktemp --tmpdir windows-vm-rdp.XXXXXX)"
      chmod 600 "$args_file"
      {
        printf '%s\n' "/v:127.0.0.1:3389"
        printf '%s\n' "/u:$user"
        [[ -n "$pass" ]] && printf '%s\n' "/p:$pass"
        printf '%s\n' "/dynamic-resolution"
        printf '%s\n' "/clipboard"
        printf '%s\n' "/cert:ignore"
        printf '%s\n' "/network:auto"
        printf '%s\n' "/scale:100"
        printf '%s\n' "+rfx"
        printf '%s\n' "/gfx:progressive"
        printf '%s\n' "/wm-class:windows-vm"
        printf '%s\n' "/t:Windows"
      } > "$args_file"

      trap 'rm -f "$args_file"' EXIT
      if command -v xfreerdp3 >/dev/null 2>&1; then
        exec xfreerdp3 /args-from:file:"$args_file"
      else
        exec xfreerdp /args-from:file:"$args_file"
      fi
    '')
  ];
}
