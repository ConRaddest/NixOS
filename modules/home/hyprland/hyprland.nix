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
      dms = {
        launcher = "dms ipc call spotlight toggle";
        processList = "dms ipc call processlist toggle";
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
      };
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
        wtype
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
          "hypr/config" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.nos.flakeDirectory}/modules/home/hyprland/config";
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
            text = ''
              return {
                launcher = ${builtins.toJSON dms.launcher},
                process_list = ${builtins.toJSON dms.processList},
                bar_toggle = nil,
                volume_up = ${builtins.toJSON dms.volumeUp},
                volume_down = ${builtins.toJSON dms.volumeDown},
                volume_mute = ${builtins.toJSON dms.volumeMute},
                mic_mute = ${builtins.toJSON dms.micMute},
                setup = function()
                  ${dms.setup}
                end,
              }
            '';
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
