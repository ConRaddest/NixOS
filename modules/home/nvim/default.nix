{ ... }:

{
  flake.lib.homeModules.nvim =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
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

      xdg.dataFile."mime/packages/code-workspace.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
          <mime-type type="application/x-code-workspace">
            <comment>Visual Studio Code Workspace</comment>
            <glob pattern="*.code-workspace"/>
          </mime-type>
        </mime-info>
      '';

      xdg.mimeApps = {
        enable = true;
        associations.added."application/x-code-workspace" = "code.desktop";
        defaultApplications."application/x-code-workspace" = "code.desktop";
      };

      home.activation.updateCodeWorkspaceMimeDatabase = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.shared-mime-info}/bin/update-mime-database ${lib.escapeShellArg "${config.xdg.dataHome}/mime"}
      '';

      xdg.configFile."nvim/lua/config.lua".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/nvim/init.lua";

      # Match Neovim to system Base16 palette.
      stylix.targets.neovim.enable = true;

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;

        plugins = with pkgs.vimPlugins; [
          tokyonight-nvim
          which-key-nvim
          snacks-nvim
          yazi-nvim
          plenary-nvim
          smart-splits-nvim
          gitsigns-nvim
          neogit
          diffview-nvim
          grug-far-nvim
          nvim-web-devicons
          bufferline-nvim
        ];

        initLua = ''
          require("config")
        '';
      };
    };
}
