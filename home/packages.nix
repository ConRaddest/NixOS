{ ... }:

{
  flake.lib.homeModules.packages =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        # dev
        vscode # text editor
        neovim # alternate text editor
        git # source control
        mkcert # local cert management

        # languages
        python3
        nodejs
        dotnet-sdk_10

        # cli utilities
        ripgrep # better
        fd # for finding directories
        jq # json cli proccessor
        eza # better ls
        zoxide # better cd
        fzf # fuzzy search
        tldr # command summaries
        tree # folder
        unzip # unzip files

        # system info
        fastfetch

        # dev tools
        lazydocker
        yazi

        # ai agents
        claude-code
        pi-coding-agent

        # communication
        chromium
        localsend

        # file manager
        nautilus

        # media
        mpv
        imv

        # language servers
        nixd
        lua-language-server
        qt6.qtdeclarative

        # formatters
        nixfmt
        stylua
      ];
    };
}
