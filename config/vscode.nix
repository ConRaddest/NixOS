{ pkgs, font, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    argvSettings."password-store" = "basic";
    profiles.default.extensions = [ pkgs.vscode-extensions.enkia.tokyo-night ];
    profiles.default.userSettings = {
      "workbench.colorTheme" = "Tokyo Night";
      "editor.fontFamily" = "'${font.mono}', monospace";
      "editor.fontLigatures" = true;
      "terminal.integrated.fontFamily" = "'${font.mono}'";
      "git.enableSmartCommit" = true;
      "workbench.iconTheme" = "file-icons";
      "explorer.confirmDelete" = false;
      "files.simpleDialog.enable" = false;
      "git.confirmSync" = false;
      "files.autoGuessEncoding" = false;
    };
  };
}
