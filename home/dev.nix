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
        lua-language-server
        nixd
        qt6.qtdeclarative

        # Formatters
        nixfmt
        stylua
      ];
    };
}
