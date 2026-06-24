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

        # AI coding agents
        claude-code
        # pi-coding-agent installed imperatively via npm so `pi update self` works.
        # See home/pi.nix; npm prefix set in home/npm.nix.
      ];
    };
}
