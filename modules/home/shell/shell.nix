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
      colors = lib.mapAttrs (_: lib.removePrefix "#") config.nos.theme.colors;

      mkNosScript =
        name: script:
        pkgs.writeShellScriptBin name ''
          export NOS_DIR="${flakeDirectory}"
          export NOS_LOCALES_FILE="${pkgs.glibcLocales}/share/i18n/SUPPORTED"
          export NOS_XKB_RULES_FILE="${pkgs.xkeyboard_config}/share/xkeyboard-config-2/rules/base.lst"
          export NOS_ZONE_TAB_FILE="${pkgs.tzdata}/share/zoneinfo/zone1970.tab"
          export NOS_ACCENT_COLOR=${lib.escapeShellArg colors.accent}
          export FZF_DEFAULT_OPTS=${lib.escapeShellArg config.home.sessionVariables.FZF_DEFAULT_OPTS}
          export PATH="${pkgs.home-manager}/bin:${pkgs.nixfmt}/bin:${pkgs.nix-search}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.git}/bin:${pkgs.mkpasswd}/bin:${pkgs.fzf}/bin:${pkgs.python3}/bin:${pkgs.curl}/bin:${pkgs.file}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${script} "$@"
        '';

      scriptDirectory = "${self}/modules/home/shell/scripts";

      nos-refresh = mkNosScript "nos-refresh" "${scriptDirectory}/nos-refresh.sh";
      nos-build = mkNosScript "nos-build" "${self}/modules/system/scripts/nos-build.sh";
      nos-update = mkNosScript "nos-update" "${self}/modules/system/scripts/nos-update.sh";
      nos-install = mkNosScript "nos-install" "${scriptDirectory}/nos-install.sh";
      nos-remove = mkNosScript "nos-remove" "${scriptDirectory}/nos-remove.sh";
      nos-webapp-install = mkNosScript "nos-webapp-install" "${scriptDirectory}/nos-webapp-install.sh";
      nos-iso-install = pkgs.writeShellScriptBin "nos-iso-install" ''
        export QEMU_FIRMWARE_DIR="${pkgs.qemu}/share/qemu"
        export PATH="/run/wrappers/bin:${
          lib.makeBinPath [
            pkgs.acl
            pkgs.coreutils
            pkgs.qemu
            pkgs.util-linux
          ]
        }:$PATH"
        exec ${pkgs.bash}/bin/bash ${scriptDirectory}/nos-iso-install.sh "$@"
      '';
      nos-iso-boot = pkgs.writeShellScriptBin "nos-iso-boot" ''
        export PATH="/run/wrappers/bin:${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.libarchive
            pkgs.systemd
            pkgs.util-linux
          ]
        }:$PATH"
        exec ${pkgs.bash}/bin/bash ${scriptDirectory}/nos-iso-boot.sh "$@"
      '';
      nos-new-host = mkNosScript "nos-new-host" "${self}/modules/system/scripts/nos-new-host.sh";

      managementPackages = lib.optionals (flakeDirectory != null) [
        nos-refresh
        nos-build
        nos-update
        nos-install
        nos-remove
        nos-webapp-install
        nos-iso-install
        nos-iso-boot
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

      # Keep Linux virtual consoles on kernel colors.
      stylix.targets.fish.enable = false;

      home = {
        packages = managementPackages ++ [
          pkgs.eza
          nos-fonts
          nos-mono-fonts
        ];
        sessionVariables = lib.optionalAttrs (flakeDirectory != null) {
          NOS_DIR = flakeDirectory;
        };
      };

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
          ''
          + lib.optionalString (flakeDirectory != null) ''

            if test -f "${flakeDirectory}/.env"
              fenv source "${flakeDirectory}/.env"
            end
          '';
          plugins = [
            {
              name = "foreign-env";
              src = pkgs.fishPlugins.foreign-env.src;
            }
          ];
          shellAliases = {
            cd = "z";
            ff = "fastfetch";
            # better ls
            ls = "eza -lh --group-directories-first --icons=auto";
            lt = "eza --tree --level=2 --long --icons --git";
            lta = "lt -a";
            lsa = "ls -a";
            # login
            start = "uwsm start hyprland-uwsm.desktop";
          };
        };
        kitty = {
          shellIntegration = {
            enableFishIntegration = true;
          };
        };
        zoxide = {
          enable = true;
          enableFishIntegration = true;
        };
      };
    };
}
