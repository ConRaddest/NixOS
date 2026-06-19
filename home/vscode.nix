{ ... }:

{
  flake.lib.homeModules.vscode =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.vscode ];
    };
}
