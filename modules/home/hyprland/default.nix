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
      colors = config.lib.stylix.colors;
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

      xdg.configFile."hypr/nix/plugins.lua".text = ''
        hl.plugin.load("${scrollOverview}/lib/libscrolloverview.so")
      '';

      xdg.configFile."hypr/nix/monitors.lua".text = ''
        return {
          ${lib.concatMapStringsSep ",\n" monitorLua host.monitors}
        }
      '';

      xdg.configFile."hypr/nix/shell.lua".text = ''
        return {
          launcher = ${builtins.toJSON desktopShell.launcher},
          process_list = ${builtins.toJSON desktopShell.processList},
          bar_toggle = ${
            if desktopShell.barToggle == null then "nil" else builtins.toJSON desktopShell.barToggle
          },
          volume_up = ${builtins.toJSON desktopShell.volumeUp},
          volume_down = ${builtins.toJSON desktopShell.volumeDown},
          volume_mute = ${builtins.toJSON desktopShell.volumeMute},
          mic_mute = ${builtins.toJSON desktopShell.micMute},
          setup = function()
            ${desktopShell.setup}
          end,
        }
      '';

      xdg.configFile."hypr/nix/input.lua".text =
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

      xdg.configFile."hypr/nix/colors.lua".text = ''
        hl.config({
          general = {
            col = {
              -- Match background to hide Hyprland xray border artifacts.
              active_border = "rgba(${colors.base00}ff)",
              inactive_border = "rgba(${colors.base00}ff)",
            },
          },
          group = {
            col = {
              border_active = "rgb(${colors.base0D})",
              border_inactive = "rgb(${colors.base03})",
              border_locked_active = "rgb(${colors.base0C})",
              border_locked_inactive = "rgb(${colors.base03})",
            },
          },
        })
      '';

      # NixOS system configuration owns portal backends.
      xdg.portal.enable = lib.mkForce false;

      # Keep Lua config live-editable while Nix owns generated support files.
      xdg.configFile."hypr/hyprland.lua".source =
        config.lib.file.mkOutOfStoreSymlink "${config.nos.flakeDirectory}/modules/home/hyprland/hyprland.lua";

      home.activation.removeLegacyHyprpolkitagent = config.lib.dag.entryBefore [ "writeBoundary" ] ''
        rm -f "$HOME/.config/systemd/user/hyprpolkitagent.service"
        rm -f "$HOME/.config/systemd/user/graphical-session.target.wants/hyprpolkitagent.service"
      '';

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
