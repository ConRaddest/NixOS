{ ... }:

{
  flake.lib.homeModules.nvim =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      colors = config.nos.theme.colors;
    in
    {
      xdg.desktopEntries.nvim = {
        name = "Neovim";
        genericName = "Text Editor";
        comment = "Edit text files in Neovim";
        exec = "kitty -o window_padding_width=0 --class neovim --title neovim -e nvim %F";
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

      xdg.configFile = {
        "nvim/lua/config.lua".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/nvim/init.lua";
        "nvim/lua/config".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/nvim/lua/config";
        "lazygit/config.yml" = {
          force = true;
          text = ''
            gui:
              nerdFontsVersion: "3"
              theme:
                activeBorderColor: ["${colors.orange}", "bold"]
                inactiveBorderColor: ["${colors.blue}"]
                searchingActiveBorderColor: ["${colors.orange}", "bold"]
                optionsTextColor: ["${colors.blue}"]
                selectedLineBgColor: ["${colors.border}"]
                cherryPickedCommitFgColor: ["${colors.blue}"]
                cherryPickedCommitBgColor: ["${colors.primary}"]
                markedBaseCommitFgColor: ["${colors.blue}"]
                markedBaseCommitBgColor: ["${colors.warning}"]
                unstagedChangesColor: ["${colors.blue}"]
                defaultFgColor: ["${colors.foreground}"]
          '';
        };
      };

      # Use Neovim's Tokyo Night theme instead of Stylix's reduced Base16 syntax palette.
      stylix.targets.neovim.enable = false;

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
          telescope-nvim
          yazi-nvim
          plenary-nvim
          smart-splits-nvim
          gitsigns-nvim
          nvim-scrollbar
          lazygit-nvim
          grug-far-nvim
          nvim-web-devicons
          bufferline-nvim
          nvim-colorizer-lua
          ccc-nvim

          # Language intelligence
          nvim-lspconfig
          blink-cmp
          friendly-snippets
          nvim-autopairs
          (nvim-treesitter.withPlugins (
            parsers: with parsers; [
              bash
              c
              c_sharp
              css
              html
              javascript
              jsdoc
              json
              lua
              markdown
              markdown_inline
              nix
              python
              qmljs
              regex
              tsx
              typescript
              vim
              vimdoc
              yaml
            ]
          ))
          nvim-treesitter-context
          nvim-ts-autotag

          # Formatting and diagnostics
          conform-nvim
          nvim-lint
          trouble-nvim

          # Testing, tasks, and sessions
          nvim-nio
          neotest
          neotest-python
          neotest-dotnet
          overseer-nvim
          persistence-nvim
        ];

        extraPackages = [ pkgs.lazygit ];

        initLua = ''
          require("config")
        '';
      };
    };
}
