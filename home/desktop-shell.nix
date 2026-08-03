{ inputs, ... }:

{
  flake.lib.homeModules.desktopShell =
    {
      config,
      desktopShell,
      lib,
      pkgs,
      self,
      ...
    }:

    {
      imports = [ inputs.dms.homeModules.dank-material-shell ];

      assertions = [
        {
          assertion = builtins.elem desktopShell [
            "dms"
            "none"
          ];
          message = "Unsupported desktopShell: ${desktopShell}";
        }
      ];

      programs.dank-material-shell = {
        enable = desktopShell == "dms";
        systemd = {
          enable = true;
          restartIfChanged = true;
        };

        # DMS owns wallpaper rendering plus runtime Material color generation.
        enableDynamicTheming = true;
      };

      home.sessionVariables.NOS_DESKTOP_SHELL = desktopShell;

      # Service managers keep environment from login time. Set this directly on
      # DMS too, so switching Qt integration does not require logging out.
      systemd.user.services.dms.Service.Environment = lib.mkIf (desktopShell == "dms") [
        "QT_QPA_PLATFORMTHEME=qt6ct"
      ];

      home.activation.ensureShellThemeTargets = lib.mkIf (desktopShell == "dms") (
        config.lib.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.config/kitty" "$HOME/.config/DankMaterialShell" "$HOME/.local/state/nos"

          migration="$HOME/.local/state/nos/dms-migration-complete"
          if [ ! -e "$migration" ]; then
            ${pkgs.quickshell}/bin/qs kill >/dev/null 2>&1 || true
            touch "$migration"
          fi

          touch "$HOME/.config/kitty/dank-theme.conf"

          session="$HOME/.local/state/DankMaterialShell/session.json"
          if [ ! -e "$session" ]; then
            mkdir -p "$(dirname "$session")"
            printf '{"wallpaperPath":"%s"}\n' "$HOME/Pictures/Wallpapers/sunset-lake.png" > "$session"
          fi

          settings="$HOME/.config/DankMaterialShell/settings.json"
          if [ ! -e "$settings" ]; then
            cat > "$settings" <<'JSON'
          {
            "gtkThemingEnabled": true,
            "qtThemingEnabled": true,
            "runDmsMatugenTemplates": true,
            "matugenTemplateGtk": true,
            "matugenTemplateHyprland": true,
            "matugenTemplateKitty": true,
            "matugenTemplateNeovim": true,
            "lockBeforeSuspend": false,
            "loginctlLockIntegration": false,
            "lockAtStartup": false
          }
          JSON
          fi
        ''
      );
    };
}
