{ ... }:

{
  flake.lib.homeModules.options =
    { lib, ... }:
    {
      options.nos = {
        flakeDirectory = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Mutable checkout path used by repository helper commands and development-mode config sources.";
        };

        trackpad = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this host has a trackpad.";
        };

        trackpadName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Hyprland input device name for this host's trackpad.";
        };

        webApps = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                id = lib.mkOption { type = lib.types.str; };
                name = lib.mkOption { type = lib.types.str; };
                url = lib.mkOption { type = lib.types.str; };
                private = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
                iconUrl = lib.mkOption { type = lib.types.str; };
                iconHash = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          default = [ ];
          description = "Chromium web applications declared with host packages.";
        };
      };
    };
}
