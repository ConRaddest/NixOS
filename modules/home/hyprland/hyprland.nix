{ ... }:

{
  flake.lib.homeModules.hyprland =
    {
      config,
      host,
      lib,
      pkgs,
      inputs,
      ...
    }:

    let
      colors = lib.mapAttrs (_: lib.removePrefix "#") config.nos.theme.colors;
      desktopShell =
        if host.desktopShell == "dms" then
          {
            launcher = "dms ipc call spotlight toggle";
            processList = "dms ipc call processlist toggle";
            barToggle = null;
            volumeUp = "dms ipc call audio increment 5";
            volumeDown = "dms ipc call audio decrement 5";
            volumeMute = "dms ipc call audio mute";
            micMute = "dms ipc call audio micmute";
            setup = ''
              require("dms.binds")
              require("dms.binds-user")
              require("dms.outputs")
              require("dms.windowrules")
              require("dms.cursor")
            '';
          }
        else if host.desktopShell == "noctalia" then
          {
            launcher = "noctalia msg panel-toggle launcher";
            processList = "noctalia msg panel-toggle control-center system";
            barToggle = ''
              sh -c 'state="$XDG_RUNTIME_DIR/noctalia-bar-autohide"; noctalia msg config-reload || exit; if test -e "$state"; then rm -f "$state"; else noctalia msg bar-auto-hide-set on && noctalia msg bar-reserve-toggle && touch "$state"; fi'
            '';
            volumeUp = "noctalia msg volume-up 5";
            volumeDown = "noctalia msg volume-down 5";
            volumeMute = "noctalia msg volume-mute";
            micMute = "noctalia msg mic-mute";
            setup = "";
          }
        else
          throw "Unsupported desktop shell: ${host.desktopShell}";
      monitorLua = monitor: ''
        {
          output = ${builtins.toJSON monitor.output},
          mode = ${builtins.toJSON monitor.mode},
          position = ${builtins.toJSON monitor.position},
          scale = ${toString monitor.scale},
          workspaces = { ${lib.concatMapStringsSep ", " toString monitor.workspaces} },
        }
      '';

      scrollOverview = pkgs.hyprlandPlugins.mkHyprlandPlugin {
        hyprland = pkgs.hyprland;
        pluginName = "scrolloverview";
        version = "0.1.0";
        src = inputs.hyprland-scroll-overview;

        buildInputs = [ pkgs.lua5_4 ];
        enableParallelBuilding = true;
        dontUseCmakeConfigure = true;

        buildPhase = ''
          runHook preBuild
          make all
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/lib"
          install -Dm755 scrolloverview.so "$out/lib/libscrolloverview.so"
          runHook postInstall
        '';

        meta = {
          description = "Scrollable workspace overview plugin for Hyprland";
          homepage = "https://github.com/yayuuu/hyprland-scroll-overview";
          license = lib.licenses.bsd3;
          platforms = lib.platforms.linux;
        };
      };
    in
    {
      # Lua config and generated adapter below render semantic colors directly.
      stylix.targets.hyprland.enable = false;

      home.packages = with pkgs; [
        cliphist
        grim
        hyprpicker
        slurp
        wl-clipboard
      ];

      home.sessionVariables = {
        GTK_USE_PORTAL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false;
      };

      # Wallpaper runs independently from desktop shell. Stylix supplies image.
      services.hyprpaper.enable = true;

      xdg = {
        configFile = {
          "hypr/hyprland.lua" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.nos.flakeDirectory}/modules/home/hyprland/hyprland.lua";
          };
          "hypr/nix/colors.lua" = {
            source = pkgs.replaceVars ./colors.lua {
              inherit (colors)
                accent
                background
                cyan
                muted
                ;
            };
          };
          "hypr/nix/theme.lua" = {
            source =
              let
                themeOverride = "${config.nos.theme.directory}/hyprland.lua";
              in
              if builtins.pathExists themeOverride then themeOverride else pkgs.writeText "hypr-theme.lua" "";
          };
          "hypr/nix/input.lua" = {
            text =
              lib.optionalString config.nos.trackpad ''
                hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
              ''
              + lib.optionalString (config.nos.trackpadName != null) ''
                hl.device({
                  name = ${builtins.toJSON config.nos.trackpadName},
                  accel_profile = "adaptive",
                  natural_scroll = true,
                  sensitivity = 0.0,
                })
              '';
          };
          "hypr/nix/monitors.lua" = {
            text = ''
              return {
                ${lib.concatMapStringsSep ",\n" monitorLua host.monitors}
              }
            '';
          };
          "hypr/nix/plugins.lua" = {
            text = ''
              hl.plugin.load("${scrollOverview}/lib/libscrolloverview.so")
            '';
          };
          "hypr/nix/shell.lua" = {
            source = pkgs.replaceVars ./shell.lua {
              barToggle =
                if desktopShell.barToggle == null then "nil" else builtins.toJSON desktopShell.barToggle;
              inherit (desktopShell) setup;
              launcher = builtins.toJSON desktopShell.launcher;
              micMute = builtins.toJSON desktopShell.micMute;
              processList = builtins.toJSON desktopShell.processList;
              volumeDown = builtins.toJSON desktopShell.volumeDown;
              volumeMute = builtins.toJSON desktopShell.volumeMute;
              volumeUp = builtins.toJSON desktopShell.volumeUp;
            };
          };
        };
        portal = {
          enable = lib.mkForce false;
        };
      };

      systemd.user.services.nos-hyprpolkitagent = {
        Unit = {
          Description = "Hyprland Polkit Agent";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
        };
        Service = {
          ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
