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
        # version control
        git

        # search
        ripgrep
        fd

        # cli utilities
        jq
        bat
        eza
        zoxide
        fzf
        tldr
        tree
        unzip

        # system info
        fastfetch

        # language servers
        nixd
        lua-language-server
        qt6.qtdeclarative

        # formatters
        nixfmt
        stylua

        # editor
        vscode

        # runtimes
        python3
        nodejs
        dotnet-sdk_10

        # dev tools
        mkcert
        lazydocker
        watchexec

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
      ];
    };
}
