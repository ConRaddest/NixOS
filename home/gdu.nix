{ ... }:

{
  flake.lib.homeModules.gdu =
    { pkgs, colors, ... }:

    {
      home.packages = [ pkgs.gdu ];

      xdg.configFile."gdu/gdu.yaml".text = ''
        # --- Detailed Interface Styling ---
        style:
          selected-row:
            text-color: "${colors.text}"
            background-color: "${colors.overlay}"

          marked:
            text-color: "${colors.base}"
            background-color: "${colors.accent}"

          header:
            text-color: "${colors.subtext}"
            number-color: "${colors.accent}"
            background-color: "${colors.base}"
            hidden: true

          result-row:
            directory-color: "${colors.accent}"
            number-color: "${colors.accent}"

          border:
            text-color: "${colors.muted}"

          footer:
            text-color: "${colors.subtext}"
            number-color: "${colors.accent}"
            background-color: "${colors.base}"

          progress-bar:
            text-color: "${colors.green}"
            background-color: "${colors.overlay}"

          progress-modal:
            current-item-path-max-len: 0
            show-disk-progress-bar: true

          dialog-box:
            text-color: "${colors.text}"
            background-color: "${colors.overlay}"

          use-old-size-bar: false

        # --- Scanning & Engine Preferences ---
        sorting:
          by: size
          order: desc
        max-cores: 12
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
