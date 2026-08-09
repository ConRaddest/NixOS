{ ... }:

{
  flake.lib.homeModules.shell =
    {
      self,
      config,
      lib,
      pkgs,
      ...
    }:

    let
      flakeDirectory = config.nos.flakeDirectory;

      mkNosScript =
        name: script:
        pkgs.writeShellScriptBin name ''
          export NOS_DIR="${flakeDirectory}"
          export PATH="${pkgs.home-manager}/bin:${pkgs.nixfmt}/bin:${pkgs.findutils}/bin:${pkgs.git}/bin:${pkgs.mkpasswd}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${script} "$@"
        '';

      scriptDirectory = "${self}/modules/home/shell/scripts";

      nos-refresh = mkNosScript "nos-refresh" "${scriptDirectory}/nos-refresh.sh";
      nos-build = mkNosScript "nos-build" "${self}/modules/system/scripts/nos-build.sh";
      nos-update = mkNosScript "nos-update" "${self}/modules/system/scripts/nos-update.sh";
      nos-install = mkNosScript "nos-install" "${scriptDirectory}/nos-install.sh";
      nos-remove = mkNosScript "nos-remove" "${scriptDirectory}/nos-remove.sh";
      nos-new-host = mkNosScript "nos-new-host" "${self}/modules/system/scripts/nos-new-host.sh";

      managementPackages = lib.optionals (flakeDirectory != null) [
        nos-refresh
        nos-build
        nos-update
        nos-install
        nos-remove
        nos-new-host
      ];

      nos-fonts = pkgs.writeShellScriptBin "nos-fonts" ''
        exec ${pkgs.fontconfig}/bin/fc-list : family | sort -u
      '';

      nos-mono-fonts = pkgs.writeShellScriptBin "nos-mono-fonts" ''
        exec ${pkgs.fontconfig}/bin/fc-list ':spacing=mono' family | sort -u
      '';

    in
    {
      home.sessionVariables = lib.optionalAttrs (flakeDirectory != null) {
        NOS_DIR = flakeDirectory;
      };

      programs.fish = {
        enable = true;
        shellAliases = {
          ls = "eza --icons";
          ll = "eza -la --icons";
          cd = "z";
          ff = "fastfetch";
          startw = "uwsm start hyprland-uwsm.desktop";
        };
        interactiveShellInit = ''
          set -g fish_greeting
        '';
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

      home.packages =
        managementPackages
        ++ (with pkgs; [
          nos-fonts
          nos-mono-fonts

          # cli utilities
          eza # better ls
          jq # json cli proccessor
          nix-search-cli # search nix packages
          tldr # command summaries
          tree # folder
          unzip # unzip files
        ]);

      programs.kitty.shellIntegration.enableFishIntegration = true;
    };
}
