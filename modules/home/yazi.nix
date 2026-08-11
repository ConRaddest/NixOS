{ ... }:

{
  flake.lib.homeModules.yazi =
    { config, pkgs, ... }:

    let
      theme = config.nos.theme.colors;
      yaziWrapper = pkgs.writeShellScriptBin "yazi-wrapper.sh" ''
        multiple="$1"
        directory="$2"
        save="$3"
        path="$4"
        out="$5"

        log="/tmp/yazi-chooser.log"
        echo "--- $(date) ---"       >> "$log"
        echo "multiple=$multiple"    >> "$log"
        echo "directory=$directory"  >> "$log"
        echo "save=$save"            >> "$log"
        echo "path=$path"            >> "$log"

        termcmd="''${TERMCMD:-kitty --title termfilechooser -e}"

        : > "$out"
        $termcmd yazi --chooser-file="$out" ''${path:+"$path"} || true

        echo "result=$(cat "$out" 2>/dev/null || echo empty)" >> "$log"

        if [ -s "$out" ] && [ "$directory" != "1" ] && [ "$save" != "1" ]; then
          selected=$(head -1 "$out")
          if [ -d "$selected" ]; then
            : > "$out"
          fi
        fi

        [ -s "$out" ] || : > "$out"
        exit 0
      '';
    in
    {
      # Custom config below renders semantic colors directly.
      stylix.targets.yazi.enable = false;

      home.packages = with pkgs; [
        imv
        mpv
        yaziWrapper
      ];

      programs.yazi = {
        enable = true;
        settings = {
          mgr = {
            ratio = [
              2
              4
              3
            ];
            show_hidden = false;
          };

          opener = {
            edit = [
              {
                run = "nvim %*";
                block = true;
                desc = "Neovim";
              }
            ];
            view = [
              {
                run = "uwsm app -- imv %*";
                block = false;
                desc = "imv";
              }
              {
                run = "xdg-open %*";
                block = false;
                desc = "Open";
              }
            ];
            play = [
              {
                run = "uwsm app -- mpv %*";
                block = false;
                desc = "mpv";
              }
            ];
            open = [
              {
                run = "xdg-open %*";
                block = false;
                desc = "Open";
              }
            ];
          };

          open.rules = [
            {
              mime = "inode/x-empty";
              use = [ "edit" ];
            }
            {
              mime = "text/*";
              use = [ "edit" ];
            }
            {
              mime = "application/{json,ld+json,javascript,typescript,x-yaml,toml,xml,x-sh,x-shellscript}";
              use = [ "edit" ];
            }
            {
              url = "*.{md,markdown,txt,log,csv,tsv,json,jsonc,yml,yaml,toml,xml,html,css,js,jsx,ts,tsx,py,sh,bash,zsh,lua,nix,rs,go,c,cpp,h,hpp}";
              use = [ "edit" ];
            }
            {
              mime = "image/*";
              use = [
                "view"
                "edit"
              ];
            }
            {
              mime = "{audio,video}/*";
              use = [ "play" ];
            }
            {
              mime = "*";
              use = [ "open" ];
            }
          ];
        };
      };

      xdg.configFile."yazi/theme.toml".text = ''
        [mgr]
        cwd             = { fg = "${theme.primary}" }
        find_keyword    = { fg = "${theme.warning}", bold = true, underline = true }
        find_position   = { fg = "${theme.foreground}", bg = "reset", bold = true }
        marker_copied   = { fg = "${theme.success}",  bg = "${theme.success}" }
        marker_cut      = { fg = "${theme.error}",    bg = "${theme.error}" }
        marker_marked   = { fg = "${theme.info}",   bg = "${theme.info}" }
        marker_selected = { fg = "${theme.warning}", bg = "${theme.warning}" }
        count_copied    = { bg = "${theme.success}" }
        count_cut       = { bg = "${theme.error}" }
        count_selected  = { bg = "${theme.warning}" }
        border_symbol   = "│"
        border_style    = { fg = "${theme.border}" }

        [indicator]
        parent  = { fg = "${theme.highlight}", bg = "${theme.selection}" }
        current = { fg = "${theme.highlight}", bg = "${theme.selection}", bold = true }
        preview = { fg = "${theme.highlight}", bg = "${theme.selection}" }
        padding = { open = "▐", close = "▌" }

        [tabs]
        active    = { fg = "${theme.selection}", bg = "${theme.primary}", bold = true }
        inactive  = { fg = "${theme.primary}", bg = "${theme.selection}" }
        sep_inner = { open = " ", close = " " }
        sep_outer = { open = " ", close = " " }

        [mode]
        normal_main = { fg = "${theme.selection}", bg = "${theme.primary}", bold = true }
        normal_alt  = { fg = "${theme.primary}", bg = "${theme.selection}" }
        select_main = { bg = "${theme.info}",   bold = true }
        select_alt  = { fg = "${theme.info}",   bg = "${theme.selection}" }
        unset_main  = { bg = "${theme.foreground}", bold = true }
        unset_alt   = { fg = "${theme.foreground}", bg = "${theme.selection}" }

        [status]
        sep_left  = { open = " ", close = " " }
        sep_right = { open = " ", close = " " }
        perm_sep        = { fg = "${theme.border}" }
        perm_type       = { fg = "${theme.primary}" }
        perm_read       = { fg = "${theme.warning}" }
        perm_write      = { fg = "${theme.error}" }
        perm_exec       = { fg = "${theme.success}" }
        progress_label  = { fg = "${theme.foreground}", bold = true }
        progress_normal = { fg = "${theme.success}", bg = "${theme.selection}" }
        progress_error  = { fg = "${theme.warning}", bg = "${theme.error}" }

        [confirm]
        border  = { fg = "${theme.primary}" }
        title   = { fg = "${theme.primary}", bold = true }
        body    = { fg = "${theme.foreground}" }
        list    = { fg = "${theme.foreground}" }
        btn_yes = { fg = "${theme.selection}", bg = "${theme.primary}", bold = true }
        btn_no  = { fg = "${theme.foreground}", bg = "${theme.selection}" }

        [pick]
        border   = { fg = "${theme.primary}" }
        active   = { fg = "${theme.foreground}", bold = true }
        inactive = { fg = "${theme.foreground}" }

        [input]
        border   = { fg = "${theme.primary}" }
        title    = { fg = "${theme.primary}" }
        value    = { fg = "${theme.foreground}" }
        selected = { reversed = true }

        [cmp]
        border   = { fg = "${theme.primary}" }
        active   = { fg = "${theme.selection}", bg = "${theme.primary}" }
        inactive = { fg = "${theme.foreground}" }

        [tasks]
        border  = { fg = "${theme.primary}" }
        title   = { fg = "${theme.primary}" }
        hovered = { fg = "${theme.foreground}", bold = true }

        [which]
        mask            = { bg = "${theme.selection}" }
        rest            = { fg = "${theme.border}" }
        desc            = { fg = "${theme.foreground}" }
        separator       = "  "
        separator_style = { fg = "${theme.border}" }

        [help]
        on      = { fg = "${theme.info}" }
        run     = { fg = "${theme.foreground}" }
        hovered = { reversed = true, bold = true }
        footer  = { bg = "${theme.foreground}" }

        [spot]
        border   = { fg = "${theme.primary}" }
        title    = { fg = "${theme.primary}" }
        tbl_cell = { fg = "${theme.foreground}", bg = "${theme.selection}" }

        [icon]
        dirs = []
        prepend_conds = [
          { if = "dir & hovered", text = "󰝰", fg = "${theme.primary}" },
          { if = "dir",           text = "󰉋", fg = "${theme.primary}" },
        ]

        [filetype]
        rules = [
          { mime = "image/*", fg = "${theme.foreground}" },
          { mime = "{audio,video}/*", fg = "${theme.foreground}" },
          { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "${theme.foreground}" },
          { mime = "application/{pdf,doc,rtf}", fg = "${theme.foreground}" },
          { mime = "vfs/{absent,stale}", fg = "${theme.foreground}" },
          { url = "*/", fg = "${theme.foreground}" },
          { url = "*", fg = "${theme.foreground}" },
        ]
      '';

      xdg.desktopEntries.yazi = {
        name = "Yazi";
        comment = "Terminal file manager";
        exec = "kitty --class yazi --title yazi -e yazi %f";
        icon = "yazi";
        terminal = false;
        type = "Application";
        mimeType = [
          "inode/directory"
          "application/x-directory"
        ];
        categories = [
          "System"
          "FileManager"
          "FileTools"
        ];
      };

      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=yazi-wrapper.sh
        default_dir=$HOME
        env=TERMCMD=kitty --class termfilechooser --title FileChooser -e
        open_mode=suggested
        save_mode=suggested
        create_help_file=1
      '';

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "yazi.desktop";
          "application/x-directory" = "yazi.desktop";
          "image/x-farbfeld" = "imv.desktop";
          "image/tiff" = "imv.desktop";
          "image/tiff-fx" = "imv.desktop";
          "image/png" = "imv.desktop";
          "image/x-png" = "imv.desktop";
          "image/jpeg" = "imv.desktop";
          "image/jpg" = "imv.desktop";
          "image/pjpeg" = "imv.desktop";
          "image/svg+xml" = "imv.desktop";
          "image/gif" = "imv.desktop";
          "image/bmp" = "imv.desktop";
          "image/x-bmp" = "imv.desktop";
          "image/heif" = "imv.desktop";
          "image/avif" = "imv.desktop";
          "image/jxl" = "imv.desktop";
          "image/webp" = "imv.desktop";
          "image/qoi" = "imv.desktop";
        };
      };
    };
}
