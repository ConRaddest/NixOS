{ inputs, ... }:

{
  flake.lib.homeModules.dms =
    {
      config,
      font,
      pkgs,
      ...
    }:

    let
      dms = "${config.programs.dank-material-shell.package}/bin/dms";
      regenerateUserTemplates = pkgs.writeShellScript "regenerate-dms-user-templates" ''
        for _ in {1..30}; do
          mode="$(${dms} ipc call theme getMode 2>/dev/null || true)"
          [[ "$mode" =~ ^(dark|light)$ ]] && exec ${dms} ipc call theme "$mode"
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        exit 1
      '';
    in
    {
      imports = [ inputs.dms.homeModules.dank-material-shell ];

      programs.dank-material-shell = {
        enable = true;
        systemd = {
          enable = true;
          restartIfChanged = true;
        };

        # DMS owns wallpaper rendering plus runtime Material color generation.
        enableDynamicTheming = true;
      };

      systemd.user.services.dms.Service = {
        Environment = [ "QT_QPA_PLATFORMTHEME=qt6ct" ];
        ExecStartPost = regenerateUserTemplates;
      };

      xdg.configFile."matugen/config.toml".text = ''
        [config]

        [templates.yazi]
        input_path = '${config.xdg.configHome}/matugen/templates/yazi.toml'
        output_path = '${config.xdg.configHome}/yazi/theme.toml'

        [templates.btop]
        input_path = '${config.xdg.configHome}/matugen/templates/btop.theme'
        output_path = '${config.xdg.configHome}/btop/themes/dms.theme'

        [templates.fzf]
        input_path = '${config.xdg.configHome}/matugen/templates/fzf-options'
        output_path = '${config.xdg.configHome}/fzf/dms-options'

        [templates.starship]
        input_path = '${config.xdg.configHome}/matugen/templates/starship.toml'
        output_path = '${config.xdg.configHome}/starship.toml'

        [templates.screen-share-picker]
        input_path = '${config.xdg.configHome}/matugen/templates/screen-share-picker.css'
        output_path = '${config.xdg.configHome}/hyprland-preview-share-picker/hyprland-preview-share-picker.css'
      '';

      home.activation.ensureDmsDefaults = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        session="$HOME/.local/state/DankMaterialShell/session.json"
        if [ ! -e "$session" ]; then
          mkdir -p "$(dirname "$session")"
          printf '{"wallpaperPath":"%s"}\n' "$HOME/Pictures/Wallpapers/sunset-lake.png" > "$session"
        fi

        settings="$HOME/.config/DankMaterialShell/settings.json"
        if [ ! -e "$settings" ]; then
          mkdir -p "$(dirname "$settings")"
          printf '%s\n' '{"loginctlLockIntegration":false,"matugenTemplateNeovim":true}' > "$settings"
        fi

        # Keep mutable DMS settings, but follow shared system monospace font.
        settings_tmp="$(${pkgs.coreutils}/bin/mktemp)"
        ${pkgs.jq}/bin/jq \
          --arg monoFont ${pkgs.lib.escapeShellArg font.mono} \
          '.monoFontFamily = $monoFont' \
          "$settings" > "$settings_tmp"
        ${pkgs.coreutils}/bin/mv "$settings_tmp" "$settings"
      '';
    };
}
