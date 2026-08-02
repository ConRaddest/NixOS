{ ... }:

{
  flake.nixosModules.cosmic =
    { inputs, ... }:

    let
      unstable = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      cosmicPackageNames = builtins.filter (name: builtins.match "cosmic.*" name != null) (
        builtins.attrNames unstable
      );
    in
    {
      # Keep the system on the pinned release channel while sourcing the full,
      # internally-coupled COSMIC package family from nixos-unstable.
      nixpkgs.overlays = [
        (
          _final: _previous:
          builtins.listToAttrs (
            map (name: {
              inherit name;
              value = unstable.${name};
            }) cosmicPackageNames
          )
          // {
            cosmic-applibrary = unstable.cosmic-app-library;
            inherit (unstable)
              pop-icon-theme
              pop-launcher
              xdg-desktop-portal-cosmic
              ;
          }
        )
      ];

      services.desktopManager.cosmic.enable = true;
      services.system76-scheduler.enable = true;

      # Keep SDDM as the shared session chooser for COSMIC, Plasma, and Hyprland.
      # cosmic-greeter is intentionally not enabled because only one display
      # manager can own the login screen.
      services.displayManager.cosmic-greeter.enable = false;
    };
}
