{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Terminal / CLI
    git
    ripgrep
    fd
    jq
    bat
    eza
    zoxide
    fzf
    fastfetch
    tldr
    tree
    unzip

    # Apps / dev
    teams-for-linux
    python3
    nodejs
    claude-code
    pi-coding-agent
    lazydocker
    firefox
    nautilus
    mpv
    imv
    localsend
  ];
}
