{ pkgs, font, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    argvSettings."disable-features" = "WaylandWindowDecorations";
    extensions = [ pkgs.vscode-extensions.enkia.tokyo-night ];
    userSettings = {
      "workbench.colorTheme" = "Tokyo Night";
      "editor.fontFamily" = "'${font.mono}', monospace";
      "editor.fontLigatures" = true;
      "terminal.integrated.fontFamily" = "'${font.mono}'";
    };
  };
}
