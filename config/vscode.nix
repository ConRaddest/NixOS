{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    commandLineArgs = [ "--disable-features=WaylandWindowDecorations" ];
    extensions = [ pkgs.vscode-extensions.enkia.tokyo-night ];
    userSettings = {
      "workbench.colorTheme" = "Tokyo Night";
    };
  };
}
