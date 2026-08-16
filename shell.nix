{
  pkgs ? import <nixpkgs> { },
}:

let
  configName = "nixos-shell-dev";
  launcher = pkgs.writeShellScriptBin "nos-shell" ''
    config_root="''${XDG_CONFIG_HOME:-"$HOME/.config"}/quickshell"
    config_path="$config_root/${configName}"

    if [[ ! -L "$config_path" ]]; then
      printf 'Missing development config symlink: %s\nRun nix develop from the repository root.\n' "$config_path" >&2
      exit 1
    fi

    export QT_QPA_PLATFORMTHEME=qt6ct
    exec ${pkgs.quickshell}/bin/qs -p "$config_path" "$@"
  '';
in
pkgs.mkShell {
  packages = [
    launcher
    pkgs.quickshell
    pkgs.qt6.qtdeclarative
    pkgs.qt6Packages.qt6ct
  ];

  shellHook = ''
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    source_path="$repo_root/shell"
    config_root="''${XDG_CONFIG_HOME:-"$HOME/.config"}/quickshell"
    config_path="$config_root/${configName}"

    if [[ ! -f "$source_path/shell.qml" ]]; then
      printf 'Quickshell source not found: %s\n' "$source_path/shell.qml" >&2
    elif [[ -e "$config_path" && ! -L "$config_path" ]]; then
      printf 'Refusing to replace existing Quickshell config: %s\n' "$config_path" >&2
      printf 'Move it or remove it, then re-enter nix develop.\n' >&2
    else
      mkdir -p "$config_root"
      ln -sfn "$source_path" "$config_path"
      export NOS_QUICKSHELL_CONFIG="$config_path"
      printf 'Quickshell dev config: %s -> %s\n' "$config_path" "$source_path"
      printf 'Run: nos-shell\n'
    fi
  '';
}
