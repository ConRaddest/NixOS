{ ... }:

{
  flake.lib.homeModules.nos =
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

        rebuild = {
          route = [ "rebuild" ];
          script = "nos-rebuild.sh";
          summary = "Rebuild and activate NixOS configuration";
          runtimeInputs = commonInputs ++ [
            pkgs.nix
            pkgs.nixfmt
            pkgs.kitty
            pkgs.uwsm
          ];
        };
        update = {
          route = [ "update" ];
          script = "nos-update.sh";
          summary = "Update flake inputs, build, and activate NixOS";
          runtimeInputs = commonInputs ++ [
            pkgs.nix
            pkgs.nixfmt
            pkgs.kitty
            pkgs.uwsm
          ];
        };
        switch = {
          route = [ "switch" ];
          script = "nos-switch.sh";
          summary = "Build and activate Home Manager configuration";
          runtimeInputs = commonInputs ++ [
            pkgs.nix
            pkgs.nixfmt
            pkgs.kitty
            pkgs.uwsm
          ];
        };
        install = {
          route = [ "install" ];
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
          route = [ "remove" ];
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
          route = [ "webapp-install" ];
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
        iso-boot = {
          route = [ "iso-boot" ];
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
      };

      commandMetadata = lib.mapAttrs (name: command: {
        inherit name;
        inherit (command) route summary;
        command = lib.concatStringsSep " " ([ "nos" ] ++ command.route);
      }) commands;

      commandRuntimeInputs = lib.unique (
        lib.concatMap (command: command.runtimeInputs) (lib.attrValues commands)
      );
      commandBody = command: ''
        ${command.environment or ""}
        exec bash "$NOS_RUNTIME_DIR/${command.script}" "$@"
      '';

      padCommand =
        name: name + lib.concatStrings (lib.replicate (lib.max 1 (18 - builtins.stringLength name)) " ");

      commandHelp = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          _: command:
          let
            route = lib.concatStringsSep " " command.route;
          in
          "  ${padCommand route}${command.summary}"
        ) commands
      );

      nos = pkgs.writeShellApplication {
        name = "nos";
        runtimeInputs = commandRuntimeInputs;
        text = ''
          export NOS_RUNTIME_DIR="${runtime}/libexec/nos"
          ${lib.optionalString (flakeDirectory != null) "export NOS_DIR=${lib.escapeShellArg flakeDirectory}"}
          export NOS_ACCENT_COLOR=${lib.escapeShellArg colors.accent}
          export FZF_DEFAULT_OPTS=${lib.escapeShellArg config.home.sessionVariables.FZF_DEFAULT_OPTS}

          usage() {
            cat <<'EOF'
          Usage: nos <command> [args...]

          Commands:
          ${commandHelp}
          EOF
          }

          command="''${1:-}"
          if [[ -z "$command" || "$command" == "help" || "$command" == "--help" || "$command" == "-h" ]]; then
            usage
            exit 0
          fi
          shift

          case "$command" in
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: command: "  ${name}) ${commandBody command} ;;") commands
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
        ++ lib.optionals (flakeDirectory != null) [ nos ];
        sessionVariables = lib.optionalAttrs (flakeDirectory != null) {
          NOS_DIR = flakeDirectory;
        };
      };

      xdg.dataFile."nos/commands.json".text = builtins.toJSON commandMetadata;
    };
}
