{ ... }:

{
  flake.lib.homeModules.npm =
    { config, pkgs, ... }:

    let
      npmPrefix = "${config.home.homeDirectory}/.npm-link";
    in
    {
      home = {
        file = {
          ".npm-link/.keep" = {
            text = "";
          };
          ".npmrc" = {
            text = ''
              prefix=${npmPrefix}
            '';
          };
        };
        packages = [ pkgs.nodejs ];
        sessionPath = [
          "${npmPrefix}/bin"
        ];
      };
    };
}
