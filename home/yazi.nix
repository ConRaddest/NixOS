{ ... }:

{
  flake.lib.homeModules.yazi =
    { colors, ... }:

    {
      xdg.configFile."yazi/theme.toml".text = ''
        [mgr]
        cwd             = { fg = "${colors.primary}" }
        find_keyword    = { fg = "${colors.yellow}", bold = true, underline = true }
        find_position   = { fg = "${colors.fg}", bg = "reset", bold = true }
        marker_copied   = { fg = "${colors.green}",   bg = "${colors.green}" }
        marker_cut      = { fg = "${colors.red}",     bg = "${colors.red}" }
        marker_marked   = { fg = "${colors.tertiary}", bg = "${colors.tertiary}" }
        marker_selected = { fg = "${colors.yellow}",  bg = "${colors.yellow}" }
        count_copied    = { fg = "${colors.bg}", bg = "${colors.green}" }
        count_cut       = { fg = "${colors.bg}", bg = "${colors.red}" }
        count_selected  = { fg = "${colors.bg}", bg = "${colors.yellow}" }
        border_symbol   = "│"
        border_style    = { fg = "${colors.fgDark}" }

        [indicator]
        parent  = { fg = "${colors.fg}",  bg = "${colors.bgLight}" }
        current = { fg = "${colors.fg}",  bg = "${colors.bgLight}" }
        preview = { fg = "${colors.fg}",  bg = "${colors.bgLight}" }
        padding = { open = "▐", close = "▌" }

        [tabs]
        active    = { fg = "${colors.bg}",      bg = "${colors.primary}", bold = true }
        inactive  = { fg = "${colors.primary}", bg = "${colors.bgLight}" }
        sep_inner = { open = " ", close = " " }
        sep_outer = { open = " ", close = " " }

        [mode]
        normal_main = { fg = "${colors.bg}",       bg = "${colors.primary}",  bold = true }
        normal_alt  = { fg = "${colors.primary}",  bg = "${colors.bgLight}" }
        select_main = { fg = "${colors.bg}",       bg = "${colors.tertiary}", bold = true }
        select_alt  = { fg = "${colors.tertiary}", bg = "${colors.bgLight}" }
        unset_main  = { fg = "${colors.bg}",       bg = "${colors.fgLight}",  bold = true }
        unset_alt   = { fg = "${colors.fgLight}",  bg = "${colors.bgLight}" }

        [status]
        sep_left  = { open = " ", close = " " }
        sep_right = { open = " ", close = " " }
        perm_sep        = { fg = "${colors.fgDark}" }
        perm_type       = { fg = "${colors.primary}" }
        perm_read       = { fg = "${colors.yellow}" }
        perm_write      = { fg = "${colors.red}" }
        perm_exec       = { fg = "${colors.green}" }
        progress_label  = { fg = "${colors.fg}", bold = true }
        progress_normal = { fg = "${colors.green}", bg = "${colors.bgLight}" }
        progress_error  = { fg = "${colors.yellow}", bg = "${colors.red}" }

        [confirm]
        border  = { fg = "${colors.primary}" }
        title   = { fg = "${colors.primary}", bold = true }
        body    = { fg = "${colors.fg}" }
        list    = { fg = "${colors.fgLight}" }
        btn_yes = { fg = "${colors.bg}", bg = "${colors.primary}", bold = true }
        btn_no  = { fg = "${colors.fg}", bg = "${colors.bgLight}" }

        [pick]
        border   = { fg = "${colors.primary}" }
        active   = { fg = "${colors.fg}", bold = true }
        inactive = { fg = "${colors.fgLight}" }

        [input]
        border   = { fg = "${colors.primary}" }
        title    = { fg = "${colors.primary}" }
        value    = { fg = "${colors.fg}" }
        selected = { reversed = true }

        [cmp]
        border   = { fg = "${colors.primary}" }
        active   = { fg = "${colors.bg}", bg = "${colors.primary}" }
        inactive = { fg = "${colors.fgLight}" }

        [tasks]
        border  = { fg = "${colors.primary}" }
        title   = { fg = "${colors.primary}" }
        hovered = { fg = "${colors.fg}", bold = true }

        [which]
        mask            = { bg = "${colors.bgLight}" }
        cand            = { fg = "${colors.tertiary}" }
        rest            = { fg = "${colors.fgDark}" }
        desc            = { fg = "${colors.fg}" }
        separator       = "  "
        separator_style = { fg = "${colors.fgDark}" }

        [help]
        on      = { fg = "${colors.tertiary}" }
        run     = { fg = "${colors.fg}" }
        hovered = { reversed = true, bold = true }
        footer  = { fg = "${colors.bg}", bg = "${colors.fgLight}" }

        [spot]
        border   = { fg = "${colors.primary}" }
        title    = { fg = "${colors.primary}" }
        tbl_col  = { fg = "${colors.tertiary}" }
        tbl_cell = { fg = "${colors.fg}", bg = "${colors.bgLight}" }

        [notify]
        title_info  = { fg = "${colors.green}" }
        title_warn  = { fg = "${colors.yellow}" }
        title_error = { fg = "${colors.red}" }

        [icon]
        dirs = []
        prepend_conds = [
          { if = "dir & hovered", text = "", fg = "${colors.primary}" },
          { if = "dir",           text = "", fg = "${colors.primary}" },
        ]

        [filetype]
        rules = [
          { mime = "image/*",                                                                                              fg = "${colors.fg}", bg = "${colors.bg}" },
          { mime = "{audio,video}/*",                                                                                     fg = "${colors.fg}", bg = "${colors.bg}" },
          { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "${colors.fg}", bg = "${colors.bg}" },
          { mime = "application/{pdf,doc,rtf}",                                                                          fg = "${colors.fg}", bg = "${colors.bg}" },
          { mime = "vfs/{absent,stale}",                                                                                  fg = "${colors.fgDark}",    bg = "${colors.bg}" },
          { url = "*/", fg = "${colors.fgLight}", bg = "${colors.bg}" },
          { url = "*",  fg = "${colors.fg}",      bg = "${colors.bg}" },
        ]
      '';

      xdg.configFile."yazi/yazi.toml".text = ''
        [opener]
        edit = [
          { run = "uwsm app -- code %*", block = false, desc = "VS Code" },
        ]
        view = [
          { run = "uwsm app -- imv %*", block = false, desc = "imv" },
        ]
        play = [
          { run = "uwsm app -- mpv %*", block = false, desc = "mpv" },
        ]

        [open]
        rules = [
          { mime = "image/*",         use = ["view", "edit"] },
          { mime = "{audio,video}/*", use = ["play", "edit"] },
          { mime = "inode/x-empty",   use = ["edit"] },
          { mime = "text/*",          use = ["edit"] },
          { mime = "application/{json,javascript,typescript,x-yaml,toml,xml,x-sh,x-shellscript}", use = ["edit"] },
          { mime = "*",               use = ["edit"] },
        ]
      '';

      xdg.configFile."yazi/scripts/fz.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          dir=$(zoxide query -i 2>/dev/null)
          [ -n "$dir" ] && ya emit cd "$dir"
        '';
      };

      xdg.configFile."yazi/scripts/ff.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          file=$(fzf 2>/dev/null)
          [ -n "$file" ] && ya emit reveal "$file"
        '';
      };

      xdg.configFile."yazi/scripts/fd.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          dir=$(fd --type d 2>/dev/null | fzf 2>/dev/null)
          [ -n "$dir" ] && ya emit cd "$dir"
        '';
      };
    };
}
