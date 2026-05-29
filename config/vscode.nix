{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    commandLineArgs = [ "--disable-features=WaylandWindowDecorations" ];
  };
}
