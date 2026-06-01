{ ... }:

{
  flake.lib.homeModules.packages =
    { pkgs, config, ... }:

    {
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        desktop = null;
        templates = null;
        publicShare = null;
        download = "${config.home.homeDirectory}/Downloads";
        documents = "${config.home.homeDirectory}/Documents";
        pictures = "${config.home.homeDirectory}/Pictures";
        music = "${config.home.homeDirectory}/Music";
        videos = "${config.home.homeDirectory}/Videos";
      };

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
        dotnet-sdk_10
        mkcert
        claude-code
        pi-coding-agent
        lazydocker
        nautilus
        mpv
        imv
        localsend
      ];
    };
}
