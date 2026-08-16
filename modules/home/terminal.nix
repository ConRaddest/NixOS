{ ... }:

{
  flake.lib.homeModules.terminal =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      colors = lib.mapAttrs (_: lib.removePrefix "#") config.nos.theme.colors;
    in
    {
      news.display = "silent";

      # Keep Linux virtual consoles on kernel colors.
      stylix.targets.fish.enable = false;

      home.packages = [ pkgs.eza ];

      programs = {
        fish = {
          enable = true;
          interactiveShellInit = ''
            set -g fish_greeting
            set -e NIXOS_OZONE_WL

            if test "$TERM" != linux
              set -g fish_color_command ${colors.accent}
              set -g fish_color_param ${colors.foreground}
            end
          '';
          shellAliases = {
            cd = "z";
            ff = "fastfetch";
            # better ls
            ls = "eza -l --group-directories-first --icons=auto";
            lt = "eza --tree --level=2 --long --icons --git";
            lta = "lt -a";
            lsa = "ls -a";
            # login
            start = "uwsm start hyprland-uwsm.desktop";
          };
        };
        kitty.shellIntegration.enableFishIntegration = true;
        zoxide = {
          enable = true;
          enableFishIntegration = true;
        };
      };
    };
}
