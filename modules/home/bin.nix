{ ... }:

{
  flake.lib.homeModules.bin =
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

      runtime = pkgs.runCommand "nos-runtime" { } ''
        install -d "$out/libexec/nos"
        cp ${self}/bin/nos-*.sh "$out/libexec/nos/"
      '';

      commonInputs = with pkgs; [
        bash
        coreutils
        git
        gnused
        ncurses
        util-linux
      ];

      commands = {
        build = {
          script = "nos-build.sh";
          summary = "Build and activate NixOS configuration";
          runtimeInputs = commonInputs ++ [
            pkgs.nix
            pkgs.nixfmt
            pkgs.kitty
            pkgs.uwsm
          ];
        };
        update = {
          script = "nos-update.sh";
          summary = "Update flake inputs, build, and activate NixOS";
          runtimeInputs = commonInputs ++ [
            pkgs.nix
            pkgs.nixfmt
            pkgs.kitty
            pkgs.uwsm
          ];
        };
        refresh = {
          script = "nos-refresh.sh";
          summary = "Build and activate Home Manager configuration";
          runtimeInputs = commonInputs ++ [
            pkgs.nix
            pkgs.nixfmt
            pkgs.kitty
            pkgs.uwsm
          ];
        };
        install = {
          script = "nos-install.sh";
          summary = "Add packages to selected host";
          runtimeInputs =
            commonInputs
            ++ (with pkgs; [
              fzf
              gawk
              gnugrep
              jq
              nix
              nix-search
              nixfmt
              python3
            ]);
        };
        remove = {
          script = "nos-remove.sh";
          summary = "Remove packages or web apps from selected host";
          runtimeInputs =
            commonInputs
            ++ (with pkgs; [
              fzf
              gawk
              gnugrep
              nix
              nixfmt
              python3
            ]);
        };
        webapp-install = {
          script = "nos-webapp-install.sh";
          summary = "Add Chromium web app to selected host";
          runtimeInputs =
            commonInputs
            ++ (with pkgs; [
              curl
              file
              fzf
              nix
              nixfmt
              python3
            ]);
        };
        iso-install = {
          script = "nos-iso-install.sh";
          summary = "Boot installer ISO in QEMU with physical target disk";
          runtimeInputs =
            commonInputs
            ++ (with pkgs; [
              acl
              qemu
            ]);
          environment = ''
            export QEMU_FIRMWARE_DIR="${pkgs.qemu}/share/qemu"
            export PATH="/run/wrappers/bin:$PATH"
          '';
        };
        iso-boot = {
          script = "nos-iso-boot.sh";
          summary = "Prepare one-time native systemd-boot ISO startup";
          runtimeInputs =
            commonInputs
            ++ (with pkgs; [
              gnugrep
              libarchive
              systemd
            ]);
          environment = ''
            export PATH="/run/wrappers/bin:$PATH"
          '';
        };
        new-host = {
          script = "nos-new-host.sh";
          summary = "Create host configuration from detected hardware";
          runtimeInputs =
            commonInputs
            ++ (with pkgs; [
              fzf
              gawk
              glibcLocales
              gnugrep
              inetutils
              mkpasswd
              nix
              nixos-install-tools
              systemd
              xkeyboard_config
            ]);
          environment = ''
            export NOS_LOCALES_FILE="${pkgs.glibcLocales}/share/i18n/SUPPORTED"
            export NOS_XKB_RULES_FILE="${pkgs.xkeyboard_config}/share/xkeyboard-config-2/rules/base.lst"
            export NOS_ZONE_TAB_FILE="${pkgs.tzdata}/share/zoneinfo/zone1970.tab"
          '';
        };
      };

      commandMetadata = lib.mapAttrs (name: command: {
        inherit name;
        inherit (command) summary;
        executable = "nos-${name}";
      }) commands;

      mkCommand =
        name: command:
        pkgs.writeShellApplication {
          name = "nos-${name}";
          inherit (command) runtimeInputs;
          text = ''
            export NOS_RUNTIME_DIR="${runtime}/libexec/nos"
            ${lib.optionalString (flakeDirectory != null) "export NOS_DIR=${lib.escapeShellArg flakeDirectory}"}
            export NOS_ACCENT_COLOR=${lib.escapeShellArg colors.accent}
            export FZF_DEFAULT_OPTS=${lib.escapeShellArg config.home.sessionVariables.FZF_DEFAULT_OPTS}
            ${command.environment or ""}
            exec bash "$NOS_RUNTIME_DIR/${command.script}" "$@"
          '';
        };

      commandPackages = lib.mapAttrsToList mkCommand commands;

      padCommand =
        name: name + lib.concatStrings (lib.replicate (lib.max 1 (18 - builtins.stringLength name)) " ");

      commandHelp = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: command: "  ${padCommand name}${command.summary}") commands
      );

      nos = pkgs.writeShellApplication {
        name = "nos";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          usage() {
            cat <<'EOF'
          Usage: nos <command> [args...]

          Commands:
          ${commandHelp}
            host new           Create host configuration from detected hardware
          EOF
          }

          command="''${1:-}"
          if [[ -z "$command" || "$command" == "help" || "$command" == "--help" || "$command" == "-h" ]]; then
            usage
            exit 0
          fi
          shift

          if [[ "$command" == "host" ]]; then
            subcommand="''${1:-}"
            [[ -n "$subcommand" ]] && shift
            if [[ "$subcommand" == "new" ]]; then
              exec nos-new-host "$@"
            fi
            printf 'Unknown nos host command: %s\n' "$subcommand" >&2
            exit 2
          fi

          case "$command" in
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: _: "  ${name}) exec nos-${name} \"\$@\" ;;") commands
          )}
            *)
              printf 'Unknown nos command: %s\n\n' "$command" >&2
              usage >&2
              exit 2
              ;;
          esac
        '';
      };

      nos-fonts = pkgs.writeShellApplication {
        name = "nos-fonts";
        runtimeInputs = [ pkgs.fontconfig ];
        text = ''
          fc-list : family | sort -u
        '';
      };

      nos-mono-fonts = pkgs.writeShellApplication {
        name = "nos-mono-fonts";
        runtimeInputs = [ pkgs.fontconfig ];
        text = ''
          fc-list ':spacing=mono' family | sort -u
        '';
      };
    in
    {
      home = {
        packages = [
          nos-fonts
          nos-mono-fonts
        ]
        ++ lib.optionals (flakeDirectory != null) ([ nos ] ++ commandPackages);
        sessionVariables = lib.optionalAttrs (flakeDirectory != null) {
          NOS_DIR = flakeDirectory;
        };
      };

      xdg.dataFile."nos/commands.json".text = builtins.toJSON commandMetadata;
    };
}
