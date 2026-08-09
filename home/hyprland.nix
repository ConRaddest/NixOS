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
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false;
      };

      # Keep plugin path declarative while preserving live, out-of-store Lua config.
      xdg.configFile."hypr/nix/plugins.lua".text = ''
        hl.plugin.load("${scrollOverview}/lib/libscrolloverview.so")
      '';

      # NixOS owns system portal backends. Other distros need Home Manager's
      # per-user Hyprland portal setup.
      xdg.portal.enable = lib.mkIf config.nos.isNixOS (lib.mkForce false);

      # Keep Lua config linked to working tree so `hyprctl reload` sees edits.
      xdg.configFile."hypr/hyprland.lua".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/config/hyprland/hyprland.lua";

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
