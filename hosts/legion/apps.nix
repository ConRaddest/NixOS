{ pkgs, ... }:

{
  home.packages = with pkgs; [
    audacity
    chromium
    cmatrix
    drawio
    gimp
    gnome-calculator
    gnome-disk-utility
    gnome-text-editor
    lazygit
    libreoffice
    librewolf
    localsend
    nautilus
    obsidian
    slack
    steam
    teams-for-linux
    vlc
    vscode
    zapzap
  ];
}
