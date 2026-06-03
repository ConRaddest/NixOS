{ ... }:

{
  flake.lib.homeModules.packages =
    {
      pkgs,
      config,
      ...
    }:

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

      # Keep npm global installs/links out of the immutable Nix store.
      # This makes commands like `npm link` write to ~/.npm-global instead.
      home.sessionPath = [
        "${config.home.homeDirectory}/.npm-global/bin"
      ];

      home.file = {
        ".npmrc".text = ''
          prefix=${config.home.homeDirectory}/.npm-global
        '';
        ".npm-global/.keep".text = "";
      };

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
