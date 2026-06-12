{ ... }:

{
  flake.lib.homeModules.packages =
    { pkgs, ... }:

    {
      xdg.desktopEntries.lazydocker = {
        name = "LazyDocker";
        comment = "Docker terminal UI";
        exec = "kitty --class lazy-docker --title lazy-docker -e lazydocker";
        icon = "docker";
        terminal = false;
        type = "Application";
        categories = [
          "Development"
          "System"
        ];
      };

      xdg.desktopEntries.nvim = {
        name = "Neovim";
        genericName = "Text Editor";
        comment = "Edit text files in Neovim";
        exec = "kitty --class neovim --title neovim -e nvim %F";
        icon = "nvim";
        terminal = false;
        type = "Application";
        categories = [
          "Utility"
          "TextEditor"
          "Development"
        ];
        mimeType = [
          "text/plain"
          "text/x-c"
          "text/x-c++"
          "text/x-chdr"
          "text/x-csrc"
          "text/x-c++hdr"
          "text/x-c++src"
          "text/x-java"
          "text/x-makefile"
          "text/x-python"
          "application/x-shellscript"
        ];
      };

      home.packages = with pkgs; [
        # portals
        xdg-desktop-portal-termfilechooser

        # dev
        vscode # text editor
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

        # personal apps
        audacity
        blender

        # system info
        fastfetch

        # dev tools
        lazydocker
        yazi

        # ai agents
        claude-code
        pi-coding-agent

        # communication
        localsend
        teams-for-linux
        whatsie
        slacky

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
