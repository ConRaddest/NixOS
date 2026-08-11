{ ... }:

{
  flake.lib.homeModules.gdu =
    {
      config,
      host,
      pkgs,
      ...
    }:

    let
      colors = config.nos.theme.colors;
    in
    {
      # Custom config below renders semantic colors directly.
      stylix.targets.gdu.enable = false;

      home.packages = [ pkgs.gdu ];

      xdg.configFile."gdu/gdu.yaml".text = ''
        style:
          selected-row:
            text-color: "${colors.background}"
            background-color: "${colors.primary}"
          result-row:
            number-color: "${colors.primary}"
            directory-color: "${colors.primary}"
          footer:
            text-color: "${colors.foreground}"
            background-color: "${colors.background}"
            number-color: "${colors.primary}"
          header:
            text-color: "${colors.foreground}"
            background-color: "${colors.background}"

        # --- Scanning & Engine Preferences ---
        sorting:
          by: size
          order: desc
        max-cores: ${toString host.gduMaxCores}
        max-path-length: 70
        depth: 0
        top: 0
        sequential-scanning: false

        # --- File Filtering ---
        ignore-dirs:
          - /proc
          - /dev
          - /sys
          - /run
        ignore-dir-patterns: []
        ignore-from-file: ""
        type: []
        exclude-type: []
        since: ""
        until: ""
        max-age: ""
        min-age: ""

        # --- Display Options ---
        show-apparent-size: false
        show-relative-size: false
        show-annexed-size: false
        show-item-count: false
        show-mtime: false
        show-in-kib: false
        use-si-prefix: false
        no-prefix: false
        reverse-sort: false
        collapse-path: false

        # --- General UI Settings ---
        no-color: false
        mouse: false
        no-unicode: false
        no-progress: false
        change-cwd: true
        browse-parent-dirs: true

        # --- Interaction & Shell ---
        interactive: false
        non-interactive: false
        no-cross: false
        no-hidden: false
        no-delete: false
        no-view-file: false
        no-spawn-shell: false
        follow-symlinks: false

        # --- Delete & Background Operations ---
        delete-in-background: true
        delete-in-parallel: false

        # --- Archive & Storage ---
        archive-browsing: false
        read-from-storage: false
        summarize: false
        profiling: false
        db: ""

        # --- I/O Files ---
        log-file: /dev/null
        input-file: ""
        output-file: ""
      '';
    };
}
