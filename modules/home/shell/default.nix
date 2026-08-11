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
      stylix = config.lib.stylix.colors;

      mkNosScript =
        name: script:
        pkgs.writeShellScriptBin name ''
          export NOS_DIR="${flakeDirectory}"
          export NOS_LOCALES_FILE="${pkgs.glibcLocales}/share/i18n/SUPPORTED"
          export NOS_XKB_RULES_FILE="${pkgs.xkeyboard_config}/share/xkeyboard-config-2/rules/base.lst"
          export NOS_ZONE_TAB_FILE="${pkgs.tzdata}/share/zoneinfo/zone1970.tab"
          export NOS_ACCENT_COLOR=${lib.escapeShellArg stylix.base0D}
          export FZF_DEFAULT_OPTS=${lib.escapeShellArg config.home.sessionVariables.FZF_DEFAULT_OPTS}
          export PATH="${pkgs.home-manager}/bin:${pkgs.nixfmt}/bin:${pkgs.findutils}/bin:${pkgs.git}/bin:${pkgs.mkpasswd}/bin:${pkgs.fzf}/bin:${pkgs.python3}/bin:$PATH"
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
      news.display = "silent";

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
        plugins = [
          {
            name = "foreign-env";
            src = pkgs.fishPlugins.foreign-env.src;
          }
        ];
        interactiveShellInit = ''
          set -g fish_greeting

          if test "$TERM" != linux
            set -g fish_color_command ${stylix.base0D}
            set -g fish_color_param ${stylix.base05}
          end
        ''
        + lib.optionalString (flakeDirectory != null) ''

          if test -f "${flakeDirectory}/.env"
            fenv source "${flakeDirectory}/.env"
          end
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
