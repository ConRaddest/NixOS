{ pkgs, ... }:

{
  home.packages = with pkgs; [
    audacity
    drawio
    gimp
    libreoffice
    localsend
    nautilus
    slack
    steam
    teams-for-linux
    vlc
    vscode
    zapzap
  ];

  nos.webApps = [
    # WEBAPPS
  ];
}
