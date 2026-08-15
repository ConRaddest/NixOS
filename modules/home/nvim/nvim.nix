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
      themeOverride = "${config.nos.theme.directory}/neovim.lua";
      themePlugin =
        if builtins.pathExists themeOverride then
          themeOverride
        else
          pkgs.writeText "neovim-theme.lua" "return {}";
      plugins = pkgs.linkFarm "neovim-plugins" [
        {
          name = "theme.lua";
          path = themePlugin;
        }
      ];
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
          "nvim/init.lua".source = ./init.lua;
          "nvim/lua/config".source = ./lua/config;
          "nvim/lua/plugins".source = plugins;
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

        extraPackages = with pkgs; [
          fd
          gcc
          git
          lazygit
          ripgrep
        ];
      };
    };
}
