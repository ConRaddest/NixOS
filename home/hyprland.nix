{ ... }:

{
  flake.lib.homeModules.hyprland =
    {
      config,
      pkgs,
      flakeDirectory,
      ...
    }:

    {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false;
      };

      # Intentional live symlink: Hyprland Lua can be edited/reloaded without a
      # Home Manager switch. This trades generation purity for fast iteration.
      xdg.configFile."hypr/hyprland.lua".source =
        config.lib.file.mkOutOfStoreSymlink "${flakeDirectory}/config/hyprland/hyprland.lua";

      home.activation.removeLegacyHyprpolkitagent = config.lib.dag.entryBefore [ "writeBoundary" ] ''
        rm -f "$HOME/.config/systemd/user/hyprpolkitagent.service"
        rm -f "$HOME/.config/systemd/user/graphical-session.target.wants/hyprpolkitagent.service"
      '';

      systemd.user.services.nos-hyprpolkitagent = {
        Unit = {
          Description = "Hyprland Polkit Agent";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
