{ ... }:

{
  flake.lib.homeModules.npm =
    { config, pkgs, ... }:

    let
      npmPrefix = "${config.home.homeDirectory}/.npm-link";
    in
    {
      home.packages = [ pkgs.nodejs ];

      # Keep `npm link` out of the immutable Nix store.
      home.sessionPath = [
        "${npmPrefix}/bin"
      ];

      home.file = {
        ".npmrc".text = ''
          prefix=${npmPrefix}
        '';
        ".npm-link/.keep".text = "";
      };
    };
}
