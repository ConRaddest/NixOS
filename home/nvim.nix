{ ... }:

{
  flake.lib.homeModules.nvim =
    { pkgs, colors, ... }:

    {
      xdg.desktopEntries.nvim = {
        name = "Neovim";
        genericName = "Text Editor";
        comment = "Edit text files in Neovim";
        exec = "kitty --class neovim --title neovim -e nvim %F";
        icon = "nvim";
        terminal = false;
        type = "Application";
        categories = [
          "Utility"
          "TextEditor"
          "Development"
        ];
        mimeType = [
          "text/plain"
          "text/x-c"
          "text/x-c++"
          "text/x-chdr"
          "text/x-csrc"
          "text/x-c++hdr"
          "text/x-c++src"
          "text/x-java"
          "text/x-makefile"
          "text/x-python"
          "application/x-shellscript"
        ];
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;

        extraPackages = with pkgs; [
          ripgrep
          fd
          wl-clipboard
        ];

        initLua = ''
          -- ─── Basics ────────────────────────────────────────────────────────
          vim.g.mapleader = " "
          vim.g.maplocalleader = " "

          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.cursorline = true
          vim.opt.signcolumn = "yes"
          vim.opt.mouse = "a"
          vim.opt.clipboard = "unnamedplus"
          vim.opt.termguicolors = true
          vim.opt.showmode = false
          vim.opt.confirm = true

          vim.opt.expandtab = true
          vim.opt.shiftwidth = 2
          vim.opt.tabstop = 2
          vim.opt.smartindent = true
          vim.opt.wrap = false
          vim.opt.linebreak = true

          vim.opt.ignorecase = true
          vim.opt.smartcase = true
          vim.opt.incsearch = true
          vim.opt.hlsearch = true

          vim.opt.splitbelow = true
          vim.opt.splitright = true
          vim.opt.scrolloff = 8
          vim.opt.sidescrolloff = 8
          vim.opt.updatetime = 250
          vim.opt.timeoutlen = 400

          -- Keep undo history across sessions.
          vim.opt.undofile = true
          vim.opt.undodir = vim.fn.stdpath("state") .. "/undo"
          vim.fn.mkdir(vim.opt.undodir:get()[1], "p")

          -- ─── Theme ─────────────────────────────────────────────────────────
          vim.cmd("highlight clear")
          vim.g.colors_name = "nixos-theme"

          local c = {
            crust = "${colors.crust}",
            mantle = "${colors.mantle}",
            base = "${colors.base}",
            surface = "${colors.surface}",
            overlay = "${colors.overlay}",
            border = "${colors.border}",
            text = "${colors.text}",
            subtext = "${colors.subtext}",
            muted = "${colors.muted}",
            faint = "${colors.faint}",
            accent = "${colors.accent}",
            red = "${colors.red}",
            orange = "${colors.orange}",
            yellow = "${colors.yellow}",
            green = "${colors.green}",
            teal = "${colors.teal}",
            cyan = "${colors.cyan}",
            blue = "${colors.blue}",
            purple = "${colors.purple}",
          }

          local function hi(group, opts)
            vim.api.nvim_set_hl(0, group, opts)
          end

          hi("Normal", { fg = c.text, bg = c.base })
          hi("NormalFloat", { fg = c.text, bg = c.surface })
          hi("FloatBorder", { fg = c.border, bg = c.surface })
          hi("CursorLine", { bg = c.surface })
          hi("CursorLineNr", { fg = c.accent, bold = true })
          hi("LineNr", { fg = c.faint })
          hi("SignColumn", { bg = c.base })
          hi("StatusLine", { fg = c.text, bg = c.mantle })
          hi("StatusLineNC", { fg = c.muted, bg = c.crust })
          hi("VertSplit", { fg = c.border })
          hi("WinSeparator", { fg = c.border })
          hi("Visual", { bg = c.overlay })
          hi("Search", { fg = c.crust, bg = c.yellow })
          hi("IncSearch", { fg = c.crust, bg = c.orange })
          hi("Pmenu", { fg = c.text, bg = c.surface })
          hi("PmenuSel", { fg = c.text, bg = c.overlay })
          hi("Comment", { fg = c.muted, italic = true })
          hi("String", { fg = c.green })
          hi("Number", { fg = c.orange })
          hi("Boolean", { fg = c.orange })
          hi("Function", { fg = c.blue })
          hi("Keyword", { fg = c.purple })
          hi("Type", { fg = c.cyan })
          hi("Identifier", { fg = c.text })
          hi("Statement", { fg = c.purple })
          hi("Constant", { fg = c.orange })
          hi("Error", { fg = c.red })
          hi("DiagnosticError", { fg = c.red })
          hi("DiagnosticWarn", { fg = c.yellow })
          hi("DiagnosticInfo", { fg = c.blue })
          hi("DiagnosticHint", { fg = c.teal })

          -- ─── Notes / todo.txt highlighting ─────────────────────────────────
          hi("NoteNumber", { fg = c.purple, bold = true })
          hi("NoteLetter", { fg = c.purple, bold = true })
          hi("NoteArrow", { fg = c.accent, bold = true })
          hi("NoteBullet", { fg = c.accent, bold = true })
          hi("NoteBracket", { fg = c.yellow })
          hi("NoteParen", { fg = c.teal, italic = true })
          hi("NoteEmail", { fg = c.blue, underline = true })
          hi("NoteImportant", { fg = c.red, bold = true })
          hi("NoteStatus", { fg = c.green, bold = true })

          vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
            pattern = { "*.txt", "TODO", "todo" },
            callback = function()
              vim.bo.filetype = "notes"
            end,
          })

          vim.api.nvim_create_autocmd("FileType", {
            pattern = "notes",
            callback = function()
              vim.bo.commentstring = "- %s"
              vim.bo.textwidth = 100
              vim.opt_local.wrap = true
              vim.opt_local.linebreak = true
              vim.opt_local.breakindent = true

              vim.cmd([==[
                syntax clear
                syntax case ignore
                syntax match NoteNumber /^\s*\d\+\(\.\d\+\)*\.\?\ze\s/
                syntax match NoteLetter /^\s*[a-z])\ze\s/
                syntax match NoteArrow /\v(->|=>)/
                syntax match NoteBullet /^\s*-\ze\s/
                syntax match NoteBracket /\[[^]]*\]/
                syntax match NoteParen /([^)]*)/
                syntax match NoteEmail /[A-Za-z0-9._%+-]\+@[A-Za-z0-9.-]\+\.[A-Za-z]\{2,}/
                syntax keyword NoteImportant bug bugs issue issues error errors fix todo TODO FIXME containedin=ALL
                syntax keyword NoteStatus Draft Complete Approved Rejected Scheduled Cancelled containedin=ALL
              ]==])
            end,
          })

          -- ─── Text-editor keymaps ───────────────────────────────────────────
          local map = vim.keymap.set
          local opts = { noremap = true, silent = true }

          map("i", "jk", "<Esc>", opts)
          map("n", "<Esc>", ":nohlsearch<CR>", opts)
          map({ "n", "i", "v" }, "<C-s>", "<Esc>:write<CR>", opts)
          map("n", "<C-q>", ":quit<CR>", opts)
          map("n", "<leader>w", ":write<CR>", opts)
          map("n", "<leader>q", ":quit<CR>", opts)
          map("n", "<leader>e", ":Explore<CR>", opts)

          map("n", "<C-h>", "<C-w>h", opts)
          map("n", "<C-j>", "<C-w>j", opts)
          map("n", "<C-k>", "<C-w>k", opts)
          map("n", "<C-l>", "<C-w>l", opts)

          -- ─── Auto-close brackets / quotes / HTML tags ─────────────────────
          local expr_opts = { noremap = true, expr = true, silent = true }

          local function next_char()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            return vim.api.nvim_get_current_line():sub(col + 1, col + 1)
          end

          local function close_or_skip(char)
            return next_char() == char and "<Right>" or char
          end

          local function smart_enter()
            local cursor = vim.api.nvim_win_get_cursor(0)
            local row = cursor[1]
            local col = cursor[2]
            local line = vim.api.nvim_get_current_line()
            local before = line:sub(1, col)
            local after = line:sub(col + 1)

            if before:sub(-1) == "{" and after:sub(1, 1) == "}" then
              local base_indent = line:match("^%s*") or ""
              local shiftwidth = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or vim.bo.tabstop
              local indent = vim.bo.expandtab and string.rep(" ", shiftwidth) or "\t"
              local middle = base_indent .. indent

              vim.api.nvim_set_current_line(before)
              vim.api.nvim_buf_set_lines(0, row, row, false, { middle, base_indent .. after })
              vim.api.nvim_win_set_cursor(0, { row + 1, #middle })
              return ""
            end

            return "\r"
          end

          map("i", "(", "()<Left>", opts)
          map("i", "[", "[]<Left>", opts)
          map("i", "{", "{}<Left>", opts)
          map("i", '"', '""<Left>', opts)
          map("i", "<CR>", smart_enter, expr_opts)
          map("i", ")", function() return close_or_skip(")") end, expr_opts)
          map("i", "]", function() return close_or_skip("]") end, expr_opts)
          map("i", "}", function() return close_or_skip("}") end, expr_opts)

          local void_tags = {
            area = true, base = true, br = true, col = true, embed = true,
            hr = true, img = true, input = true, link = true, meta = true,
            param = true, source = true, track = true, wbr = true,
          }

          map("i", ">", function()
            local ft = vim.bo.filetype
            if not ({ html = true, xml = true, javascriptreact = true, typescriptreact = true, svelte = true, vue = true })[ft] then
              return ">"
            end

            local col = vim.api.nvim_win_get_cursor(0)[2]
            local before = vim.api.nvim_get_current_line():sub(1, col)
            local tag = before:match("<([%w:_-]+)[^<>]*$")

            if not tag or before:match("</[%w:_-]+[^<>]*$") or before:match("/%s*$") or void_tags[tag:lower()] then
              return ">"
            end

            return "></" .. tag .. ">" .. string.rep("<Left>", #tag + 3)
          end, expr_opts)

          -- Friendlier netrw file browser.
          vim.g.netrw_banner = 0
          vim.g.netrw_liststyle = 3
          vim.g.netrw_browse_split = 0
          vim.g.netrw_winsize = 25
        '';
      };
    };
}
