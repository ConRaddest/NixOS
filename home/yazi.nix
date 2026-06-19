{ ... }:

{
  flake.lib.homeModules.yazi =
    {
      pkgs,
      colors,
      ...
    }:

    let
      yazi-wrapper = pkgs.writeShellScriptBin "yazi-wrapper.sh" ''
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

        echo "result=$(cat "$out" 2>/dev/null || echo EMPTY)" >> "$log"

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
        yazi
        yazi-wrapper
        xdg-desktop-portal-termfilechooser
      ];

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

      xdg.configFile."yazi/yazi.toml".text = ''
        [mgr]
        ratio = [2, 4, 3]
        show_hidden = false

        [opener]
        edit = [
          { run = "uwsm app -- code --reuse-window %*", block = false, desc = "VS Code" },
        ]
        view = [
          { run = "uwsm app -- imv %*", block = false, desc = "imv" },
          { run = "xdg-open %*", block = false, desc = "Open" },
        ]
        play = [
          { run = "uwsm app -- mpv %*", block = false, desc = "mpv" },
        ]
        open = [
          { run = "xdg-open %*", block = false, desc = "Open" },
        ]

        [open]
        rules = [
          { mime = "inode/x-empty",   use = ["edit"] },
          { mime = "text/*",          use = ["edit"] },
          { mime = "application/{json,ld+json,javascript,typescript,x-yaml,toml,xml,x-sh,x-shellscript}", use = ["edit"] },
          { url = "*.{md,markdown,txt,log,csv,tsv,json,jsonc,yml,yaml,toml,xml,html,css,js,jsx,ts,tsx,py,sh,bash,zsh,lua,nix,rs,go,c,cpp,h,hpp}", use = ["edit"] },
          { mime = "image/*",         use = ["view", "edit"] },
          { mime = "{audio,video}/*", use = ["play"] },
          { mime = "*",               use = ["open"] },
        ]
      '';

      xdg.configFile."yazi/theme.toml".text = ''
        [mgr]
        cwd             = { fg = "${colors.accent}" }
        find_keyword    = { fg = "${colors.yellow}", bold = true, underline = true }
        find_position   = { fg = "${colors.text}", bg = "reset", bold = true }
        marker_copied   = { fg = "${colors.green}",  bg = "${colors.green}" }
        marker_cut      = { fg = "${colors.red}",    bg = "${colors.red}" }
        marker_marked   = { fg = "${colors.teal}",   bg = "${colors.teal}" }
        marker_selected = { fg = "${colors.yellow}", bg = "${colors.yellow}" }
        count_copied    = { fg = "${colors.base}", bg = "${colors.green}" }
        count_cut       = { fg = "${colors.base}", bg = "${colors.red}" }
        count_selected  = { fg = "${colors.base}", bg = "${colors.yellow}" }
        border_symbol   = "│"
        border_style    = { fg = "${colors.muted}" }

        [indicator]
        parent  = { fg = "${colors.text}", bg = "${colors.overlay}" }
        current = { fg = "${colors.text}", bg = "${colors.overlay}" }
        preview = { fg = "${colors.text}", bg = "${colors.overlay}" }
        padding = { open = "▐", close = "▌" }

        [tabs]
        active    = { fg = "${colors.base}",   bg = "${colors.accent}", bold = true }
        inactive  = { fg = "${colors.accent}", bg = "${colors.overlay}" }
        sep_inner = { open = " ", close = " " }
        sep_outer = { open = " ", close = " " }

        [mode]
        normal_main = { fg = "${colors.base}",   bg = "${colors.accent}", bold = true }
        normal_alt  = { fg = "${colors.accent}", bg = "${colors.overlay}" }
        select_main = { fg = "${colors.base}",   bg = "${colors.teal}",   bold = true }
        select_alt  = { fg = "${colors.teal}",   bg = "${colors.overlay}" }
        unset_main  = { fg = "${colors.base}",   bg = "${colors.subtext}", bold = true }
        unset_alt   = { fg = "${colors.subtext}", bg = "${colors.overlay}" }

        [status]
        sep_left  = { open = " ", close = " " }
        sep_right = { open = " ", close = " " }
        perm_sep        = { fg = "${colors.muted}" }
        perm_type       = { fg = "${colors.accent}" }
        perm_read       = { fg = "${colors.yellow}" }
        perm_write      = { fg = "${colors.red}" }
        perm_exec       = { fg = "${colors.green}" }
        progress_label  = { fg = "${colors.text}", bold = true }
        progress_normal = { fg = "${colors.green}", bg = "${colors.overlay}" }
        progress_error  = { fg = "${colors.yellow}", bg = "${colors.red}" }

        [confirm]
        border  = { fg = "${colors.accent}" }
        title   = { fg = "${colors.accent}", bold = true }
        body    = { fg = "${colors.text}" }
        list    = { fg = "${colors.subtext}" }
        btn_yes = { fg = "${colors.base}", bg = "${colors.accent}", bold = true }
        btn_no  = { fg = "${colors.text}", bg = "${colors.overlay}" }

        [pick]
        border   = { fg = "${colors.accent}" }
        active   = { fg = "${colors.text}", bold = true }
        inactive = { fg = "${colors.subtext}" }

        [input]
        border   = { fg = "${colors.accent}" }
        title    = { fg = "${colors.accent}" }
        value    = { fg = "${colors.text}" }
        selected = { reversed = true }

        [cmp]
        border   = { fg = "${colors.accent}" }
        active   = { fg = "${colors.base}", bg = "${colors.accent}" }
        inactive = { fg = "${colors.subtext}" }

        [tasks]
        border  = { fg = "${colors.accent}" }
        title   = { fg = "${colors.accent}" }
        hovered = { fg = "${colors.text}", bold = true }

        [which]
        mask            = { bg = "${colors.overlay}" }
        cand            = { fg = "${colors.teal}" }
        rest            = { fg = "${colors.muted}" }
        desc            = { fg = "${colors.text}" }
        separator       = "  "
        separator_style = { fg = "${colors.muted}" }

        [help]
        on      = { fg = "${colors.teal}" }
        run     = { fg = "${colors.text}" }
        hovered = { reversed = true, bold = true }
        footer  = { fg = "${colors.base}", bg = "${colors.subtext}" }

        [spot]
        border   = { fg = "${colors.accent}" }
        title    = { fg = "${colors.accent}" }
        tbl_col  = { fg = "${colors.teal}" }
        tbl_cell = { fg = "${colors.text}", bg = "${colors.overlay}" }

        [notify]
        title_info  = { fg = "${colors.green}" }
        title_warn  = { fg = "${colors.yellow}" }
        title_error = { fg = "${colors.red}" }

        [icon]
        dirs = []
        prepend_conds = [
          { if = "dir & hovered", text = "󰝰", fg = "${colors.accent}" },
          { if = "dir",           text = "󰉋", fg = "${colors.accent}" },
        ]

        [filetype]
        rules = [
          { mime = "image/*",                                                                                              fg = "${colors.text}", bg = "${colors.base}" },
          { mime = "{audio,video}/*",                                                                                     fg = "${colors.text}", bg = "${colors.base}" },
          { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "${colors.text}", bg = "${colors.base}" },
          { mime = "application/{pdf,doc,rtf}",                                                                          fg = "${colors.text}", bg = "${colors.base}" },
          { mime = "vfs/{absent,stale}",                                                                                  fg = "${colors.muted}",   bg = "${colors.base}" },
          { url = "*/", fg = "${colors.subtext}", bg = "${colors.base}" },
          { url = "*",  fg = "${colors.text}",    bg = "${colors.base}" },
        ]
      '';
    };
}
