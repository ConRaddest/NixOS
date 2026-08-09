{ ... }:

{
  flake.lib.homeModules.hyprland =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:

    let
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

      # Keep plugin path declarative while preserving live, out-of-store Lua config.
      xdg.configFile."hypr/nix/plugins.lua".text = ''
        hl.plugin.load("${scrollOverview}/lib/libscrolloverview.so")
      '';

      # NixOS system configuration owns portal backends.
      xdg.portal.enable = lib.mkForce false;

      # Keep Lua config linked to working tree when flake checkout is known.
      # Fall back to store copy for reusable modules without a checkout path.
      xdg.configFile."hypr/hyprland.lua".source =
        if config.nos.flakeDirectory != null then
          config.lib.file.mkOutOfStoreSymlink "${config.nos.flakeDirectory}/modules/home/hyprland/hyprland.lua"
        else
          ./hyprland.lua;

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
