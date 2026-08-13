{ ... }:

{
  flake.lib.homeModules.dev =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        # Languages / runtimes
        dotnet-sdk_10
        python3
        python3Packages.debugpy
        netcoredbg

        # Search / project navigation
        fd
        ripgrep
        ast-grep
        tree-sitter

        # Language servers
        lua-language-server
        nixd
        qt6.qtdeclarative
        basedpyright
        roslyn-ls
        bash-language-server
        typescript
        typescript-language-server
        vscode-langservers-extracted
        tailwindcss-language-server
        emmet-language-server
        glsl_analyzer
        yaml-language-server
        clang-tools

        # Formatters / linters
        nixfmt
        stylua
        ruff
        shellcheck
        shfmt
        prettierd
        csharpier
        statix
        deadnix
      ];
    };
}
