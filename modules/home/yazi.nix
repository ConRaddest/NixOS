{ ... }:

{
  flake.lib.homeModules.yazi =
    { config, pkgs, ... }:

    let
      stylix = config.lib.stylix.colors.withHashtag;
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
      home.packages = with pkgs; [
        imv
        mpv
        yaziWrapper
        xdg-desktop-portal-termfilechooser
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
        cwd             = { fg = "${stylix.base0D}" }
        find_keyword    = { fg = "${stylix.base0A}", bold = true, underline = true }
        find_position   = { fg = "${stylix.base05}", bg = "reset", bold = true }
        marker_copied   = { fg = "${stylix.base0B}",  bg = "${stylix.base0B}" }
        marker_cut      = { fg = "${stylix.base08}",    bg = "${stylix.base08}" }
        marker_marked   = { fg = "${stylix.base0C}",   bg = "${stylix.base0C}" }
        marker_selected = { fg = "${stylix.base0A}", bg = "${stylix.base0A}" }
        count_copied    = { bg = "${stylix.base0B}" }
        count_cut       = { bg = "${stylix.base08}" }
        count_selected  = { bg = "${stylix.base0A}" }
        border_symbol   = "│"
        border_style    = { fg = "${stylix.base03}" }

        [indicator]
        parent  = { fg = "${stylix.base06}", bg = "${stylix.base02}" }
        current = { fg = "${stylix.base06}", bg = "${stylix.base02}", bold = true }
        preview = { fg = "${stylix.base06}", bg = "${stylix.base02}" }
        padding = { open = "▐", close = "▌" }

        [tabs]
        active    = { fg = "${stylix.base02}", bg = "${stylix.base0D}", bold = true }
        inactive  = { fg = "${stylix.base0D}", bg = "${stylix.base02}" }
        sep_inner = { open = " ", close = " " }
        sep_outer = { open = " ", close = " " }

        [mode]
        normal_main = { fg = "${stylix.base02}", bg = "${stylix.base0D}", bold = true }
        normal_alt  = { fg = "${stylix.base0D}", bg = "${stylix.base02}" }
        select_main = { bg = "${stylix.base0C}",   bold = true }
        select_alt  = { fg = "${stylix.base0C}",   bg = "${stylix.base02}" }
        unset_main  = { bg = "${stylix.base05}", bold = true }
        unset_alt   = { fg = "${stylix.base05}", bg = "${stylix.base02}" }

        [status]
        sep_left  = { open = " ", close = " " }
        sep_right = { open = " ", close = " " }
        perm_sep        = { fg = "${stylix.base03}" }
        perm_type       = { fg = "${stylix.base0D}" }
        perm_read       = { fg = "${stylix.base0A}" }
        perm_write      = { fg = "${stylix.base08}" }
        perm_exec       = { fg = "${stylix.base0B}" }
        progress_label  = { fg = "${stylix.base05}", bold = true }
        progress_normal = { fg = "${stylix.base0B}", bg = "${stylix.base02}" }
        progress_error  = { fg = "${stylix.base0A}", bg = "${stylix.base08}" }

        [confirm]
        border  = { fg = "${stylix.base0D}" }
        title   = { fg = "${stylix.base0D}", bold = true }
        body    = { fg = "${stylix.base05}" }
        list    = { fg = "${stylix.base05}" }
        btn_yes = { fg = "${stylix.base02}", bg = "${stylix.base0D}", bold = true }
        btn_no  = { fg = "${stylix.base05}", bg = "${stylix.base02}" }

        [pick]
        border   = { fg = "${stylix.base0D}" }
        active   = { fg = "${stylix.base05}", bold = true }
        inactive = { fg = "${stylix.base05}" }

        [input]
        border   = { fg = "${stylix.base0D}" }
        title    = { fg = "${stylix.base0D}" }
        value    = { fg = "${stylix.base05}" }
        selected = { reversed = true }

        [cmp]
        border   = { fg = "${stylix.base0D}" }
        active   = { fg = "${stylix.base02}", bg = "${stylix.base0D}" }
        inactive = { fg = "${stylix.base05}" }

        [tasks]
        border  = { fg = "${stylix.base0D}" }
        title   = { fg = "${stylix.base0D}" }
        hovered = { fg = "${stylix.base05}", bold = true }

        [which]
        mask            = { bg = "${stylix.base02}" }
        rest            = { fg = "${stylix.base03}" }
        desc            = { fg = "${stylix.base05}" }
        separator       = "  "
        separator_style = { fg = "${stylix.base03}" }

        [help]
        on      = { fg = "${stylix.base0C}" }
        run     = { fg = "${stylix.base05}" }
        hovered = { reversed = true, bold = true }
        footer  = { bg = "${stylix.base05}" }

        [spot]
        border   = { fg = "${stylix.base0D}" }
        title    = { fg = "${stylix.base0D}" }
        tbl_cell = { fg = "${stylix.base05}", bg = "${stylix.base02}" }

        [icon]
        dirs = []
        prepend_conds = [
          { if = "dir & hovered", text = "󰝰", fg = "${stylix.base0D}" },
          { if = "dir",           text = "󰉋", fg = "${stylix.base0D}" },
        ]

        [filetype]
        rules = [
          { mime = "image/*", fg = "${stylix.base05}" },
          { mime = "{audio,video}/*", fg = "${stylix.base05}" },
          { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "${stylix.base05}" },
          { mime = "application/{pdf,doc,rtf}", fg = "${stylix.base05}" },
          { mime = "vfs/{absent,stale}", fg = "${stylix.base05}" },
          { url = "*/", fg = "${stylix.base05}" },
          { url = "*", fg = "${stylix.base05}" },
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
        };
      };
    };
}
