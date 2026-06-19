{ ... }:

{
  flake.lib.homeModules.unimatrix =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.unimatrix ];

      programs.bash.shellAliases = {
        matrix = "unimatrix --color=magenta";
        unimatrix = "unimatrix --color=magenta";
      };
    };
}
