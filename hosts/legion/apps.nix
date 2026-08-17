{ pkgs, ... }:

{
  home.packages = with pkgs; [
    audacity
    chromium
    claude-code
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

  nos.webApps = [
    {
      id = "youtube";
      name = "YouTube";
      url = "https://www.youtube.com/";
      private = false;
      iconUrl = "https://www.google.com/s2/favicons?domain=https://www.youtube.com/&sz=256";
      iconHash = "sha256-y2rbGYQ7ZFvCJxgfUnRvAemo/abBEzjKwjxZd8fSOGw=";
    }
    {
      id = "gmail";
      name = "Gmail";
      url = "https://mail.google.com/mail/u/0/#inbox";
      private = false;
      iconUrl = "https://www.google.com/s2/favicons?domain=https://mail.google.com/mail/u/0/&sz=256";
      iconHash = "sha256-uvp1erTkKXGuCXxFS5ZWm8fg4Sa0g7bdiT34YaClscM=";
    }
    {
      id = "google-drive";
      name = "Google Drive";
      url = "https://drive.google.com/drive/my-drive";
      private = false;
      iconUrl = "https://www.google.com/s2/favicons?domain=https://drive.google.com/drive/my-drive&sz=256";
      iconHash = "sha256-Q2CC+4/ZmvKJ1CPQqRPlUWR2lo7PvyMsZTPXAMxpSq4=";
    }
    {
      id = "google-maps";
      name = "Google Maps";
      url = "https://maps.google.com/maps";
      private = false;
      iconUrl = "https://www.google.com/s2/favicons?domain=https://maps.google.com/maps&sz=256";
      iconHash = "sha256-4xGybzQQ5dGUsnZLIt0dENBYk6t4pcEYfQy6hoNy6vg=";
    }
    {
      id = "chatgpt";
      name = "ChatGPT";
      url = "https://chatgpt.com/";
      private = false;
      iconUrl = "https://www.google.com/s2/favicons?domain=https://chatgpt.com/&sz=256";
      iconHash = "sha256-kma57MEuQyyD54Pd8NPplY4T7E6s20exD2F6zfXXAUY=";
    }
    {
      id = "yt-music";
      name = "YT Music";
      url = "https://music.youtube.com/";
      private = false;
      iconUrl = "https://www.google.com/s2/favicons?domain=https://music.youtube.com/&sz=256";
      iconHash = "sha256-f5M74vVmAmIrigDa0PWVPvZr88RJXLqKrTcqt8T9/Fs=";
    }
    # WEBAPPS
  ];
}
