{ config, pkgs, font, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
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
    };

    argvSettings = {
      "password-store" = "basic";
      "enable-crash-reporter" = true;
	    "crash-reporter-id" = "d82ab34d-9a94-4552-98fc-23b1e3f0737b";
    };
  };
}
