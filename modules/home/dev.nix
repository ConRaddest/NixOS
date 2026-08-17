{ ... }:

{
  flake.lib.homeModules.dev =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        # Languages / runtimes
        dotnet-sdk_10
        python3

        # Search / project navigation
        fd
        ripgrep

        # Language servers
        nixd
        qt6.qtdeclarative
        lua-language-server

        # Formatters / linters
        nixfmt
        stylua
      ];
    };
}
