{ ... }:

{
  flake.lib.homeModules.nvim =
    {
      config,
      pkgs,
      ...
    }:

    let
      colors = config.nos.theme.colors;
    in
    {
      xdg = {
        configFile = {
          "lazygit/config.yml" = {
            force = true;
            source = pkgs.replaceVars ./lazygit.yaml {
              inherit (colors)
                accent
                blue
                foreground
                muted
                orange
                yellow
                ;
            };
          };
          "nvim/lua/config" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/nvim/lua/config";
          };
          "nvim/lua/config.lua" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/nvim/init.lua";
          };
          "nvim/lua/nix/theme.lua".text = ''
            return {
              muted = ${builtins.toJSON colors.muted},
            }
          '';
        };
        dataFile = {
          "mime/packages/code-workspace.xml" = {
            text = ''
              <?xml version="1.0" encoding="UTF-8"?>
              <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
                <mime-type type="application/x-code-workspace">
                  <comment>Visual Studio Code Workspace</comment>
                  <glob pattern="*.code-workspace"/>
                </mime-type>
              </mime-info>
            '';
          };
        };
        desktopEntries = {
          nvim = {
            categories = [
              "Utility"
              "TextEditor"
              "Development"
            ];
            comment = "Edit text files in Neovim";
            exec = "kitty -o window_padding_width=0 --class neovim --title neovim -e nvim %F";
            genericName = "Text Editor";
            icon = "nvim";
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
            name = "Neovim";
            terminal = false;
            type = "Application";
          };
        };
        mimeApps = {
          associations = {
            added = {
              "application/x-code-workspace" = "code.desktop";
            };
          };
          defaultApplications = {
            "application/x-code-workspace" = "code.desktop";
          };
          enable = true;
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
