{ ... }:

{
  flake.lib.homeModules.shell =
    {
      self,
      pkgs,
      flakeDirectory,
      ...
    }:

    let
      mkNosScript =
        name: script:
        pkgs.writeShellScriptBin name ''
          export NOS_DIR="${flakeDirectory}"
          export PATH="${pkgs.home-manager}/bin:${pkgs.nixfmt}/bin:${pkgs.findutils}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${script} "$@"
        '';

      nos-refresh = mkNosScript "nos-refresh" "${self}/scripts/system/nos-refresh.sh";
      nos-build = mkNosScript "nos-build" "${self}/scripts/system/nos-build.sh";
      nos-update = mkNosScript "nos-update" "${self}/scripts/system/nos-update.sh";
      nos-install = mkNosScript "nos-install" "${self}/scripts/system/nos-install.sh";
      nos-remove = mkNosScript "nos-remove" "${self}/scripts/system/nos-remove.sh";

      nos-fonts = pkgs.writeShellScriptBin "nos-fonts" ''
        exec ${pkgs.fontconfig}/bin/fc-list : family | sort -u
      '';

      nos-mono-fonts = pkgs.writeShellScriptBin "nos-mono-fonts" ''
        exec ${pkgs.fontconfig}/bin/fc-list ':spacing=mono' family | sort -u
      '';

    in
    {
      home.sessionVariables.NOS_DIR = flakeDirectory;

      programs.fish = {
        enable = true;
        shellAliases = {
          ls = "eza --icons";
          ll = "eza -la --icons";
          cd = "z";
          ff = "fastfetch";
          startw = "uwsm start hyprland-uwsm.desktop";
        };
        plugins = [
          {
            name = "foreign-env";
            src = pkgs.fishPlugins.foreign-env.src;
          }
        ];
        interactiveShellInit = ''
          set -g fish_greeting

          if test -f "${flakeDirectory}/.env"
            fenv source "${flakeDirectory}/.env"
          end
        '';
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

      home.packages = with pkgs; [
        nos-refresh
        nos-build
        nos-update
        nos-install
        nos-remove
        nos-fonts
        nos-mono-fonts

        # cli utilities
        eza # better ls
        jq # json cli proccessor
        nix-search-cli # search nix packages
        tldr # command summaries
        tree # folder
        unzip # unzip files
      ];

      programs.kitty.shellIntegration.enableFishIntegration = true;
    };
}
