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
      colors = config.lib.stylix.colors.withHashtag;
    in
    {
      home.packages = [ pkgs.gdu ];

      xdg.configFile."gdu/gdu.yaml".text = ''
        style:
          selected-row:
            text-color: "${colors.base00}"
            background-color: "${colors.base0D}"
          result-row:
            number-color: "${colors.base0D}"
            directory-color: "${colors.base0D}"
          footer:
            text-color: "${colors.base05}"
            background-color: "${colors.base00}"
            number-color: "${colors.base0D}"
          header:
            text-color: "${colors.base05}"
            background-color: "${colors.base00}"

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
