vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Space>", "<Nop>", {
  silent = true,
})

require("tokyonight").setup({
  style = "night",
})
vim.cmd.colorscheme("tokyonight")

local function transparent_number_column()
  vim.cmd([[
    highlight LineNr guibg=NONE ctermbg=NONE
    highlight CursorLine guibg=#24283b
    highlight CursorLineNr guifg=#7aa2f7 guibg=NONE gui=bold
    highlight SignColumn guibg=NONE ctermbg=NONE
    highlight FoldColumn guibg=NONE ctermbg=NONE
  ]])
end

transparent_number_column()

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = transparent_number_column,
})

vim.opt.fillchars:append({
  vert = " ",
  diff = " ",
})

local which_key = require("which-key")

which_key.setup({
  preset = "modern",
  delay = 150,
})

local snacks_editor_window

local function focus_snacks_editor()
  if
    snacks_editor_window
    and vim.api.nvim_win_is_valid(snacks_editor_window)
    and vim.api.nvim_win_get_tabpage(snacks_editor_window) == vim.api.nvim_get_current_tabpage()
  then
    vim.api.nvim_set_current_win(snacks_editor_window)
    return
  end

  vim.cmd("wincmd l")
end

local function toggle_snacks_explorer()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]

  if explorer then
    explorer:close()
    vim.schedule(focus_snacks_editor)
    return
  end

  snacks_editor_window = vim.api.nvim_get_current_win()
  Snacks.explorer({ focus = true })
end

local function save_current_buffer()
  if vim.api.nvim_buf_get_name(0) ~= "" then
    vim.cmd("write")
    return
  end

  local path = vim.fn.input("Save as: ", vim.fn.getcwd() .. "/", "file")

  if path ~= "" then
    vim.cmd("write " .. vim.fn.fnameescape(path))
  end
end

which_key.add({
  {
    "<leader><leader>",
    function()
      Snacks.picker.files()
    end,
    desc = "Find files",
  },
  {
    "<C-b>",
    toggle_snacks_explorer,
    desc = "Snacks explorer",
  },
  { "<M-Left>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
  { "<M-Right>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
  { "<leader>v", "<cmd>vsplit<cr>", desc = "Vertical split" },
  { "<leader>h", "<cmd>split<cr>", desc = "Horizontal split" },
  { "<leader>c", "<cmd>close<cr>", desc = "Close split" },
  { "<leader>o", "<C-w>o", desc = "Close other splits" },
  { "<leader>=", "<C-w>=", desc = "Equalize splits" },
  { "<leader>e", "<cmd>Yazi<cr>", desc = "File explorer" },
  { "<leader>g", group = "Git" },
  { "<leader>gg", "<cmd>Neogit<cr>", desc = "Git status" },
  { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Review changes" },
  { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
  { "<leader>s", group = "Search" },
  {
    "<leader>sr",
    function()
      if vim.bo.filetype:match("^snacks_picker") then
        focus_snacks_editor()
      end

      vim.cmd("GrugFar")
    end,
    desc = "Search and replace",
  },
  { "<C-q>", "<cmd>quitall!<cr>", desc = "Quit Neovim" },
  { "<leader>w", "<cmd>write<cr>", desc = "Save" },
  { "<C-s>", save_current_buffer, desc = "Save" },
})

vim.keymap.set("n", "<C-c>", function()
  local split_count = 0

  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(window).relative == "" then
      split_count = split_count + 1
    end
  end

  if split_count > 1 then
    local buffer = vim.api.nvim_get_current_buf()
    local window = vim.api.nvim_get_current_win()

    vim.api.nvim_win_close(window, true)

    if vim.api.nvim_buf_is_valid(buffer) then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end

    return
  end

  Snacks.bufdelete()
end, {
  desc = "Close split or buffer",
  nowait = true,
})

vim.keymap.set("i", "<C-s>", function()
  vim.cmd("stopinsert")
  vim.schedule(save_current_buffer)
end, {
  desc = "Exit insert mode and save",
})

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", {
  desc = "Clear search highlighting",
})

vim.keymap.set("x", "<C-f>", function()
  vim.cmd("normal! y")

  local text = vim.fn.getreg('"'):gsub("\n", "\\n")
  local pattern = "\\V" .. vim.fn.escape(text, "\\")

  vim.fn.setreg("/", pattern)
  vim.opt.hlsearch = true
  vim.cmd("normal! n")
end, {
  desc = "Search selected text",
})

-- abosulute line numbers
vim.opt.cursorline = true
vim.opt.cursorlineopt = "both"
vim.opt.number = true
vim.opt.statuscolumn = "  %s%l  "
vim.opt.relativenumber = false
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.mouse = "a"

local smart_splits = require("smart-splits")

smart_splits.setup({
  at_edge = "stop",
  default_amount = 3,
})

vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left, { desc = "Focus left split" })
vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down, { desc = "Focus lower split" })
vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up, { desc = "Focus upper split" })
vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right, { desc = "Focus right split" })
vim.keymap.set("n", "<C-Left>", smart_splits.move_cursor_left, { desc = "Focus left split" })
vim.keymap.set("n", "<C-Down>", smart_splits.move_cursor_down, { desc = "Focus lower split" })
vim.keymap.set("n", "<C-Up>", smart_splits.move_cursor_up, { desc = "Focus upper split" })
vim.keymap.set("n", "<C-Right>", smart_splits.move_cursor_right, { desc = "Focus right split" })

vim.keymap.set("n", "<M-h>", smart_splits.resize_left, { desc = "Resize split left" })
vim.keymap.set("n", "<M-j>", smart_splits.resize_down, { desc = "Resize split down" })
vim.keymap.set("n", "<M-k>", smart_splits.resize_up, { desc = "Resize split up" })
vim.keymap.set("n", "<M-l>", smart_splits.resize_right, { desc = "Resize split right" })

vim.keymap.set("n", "<leader>H", smart_splits.swap_buf_left, { desc = "Swap split left" })
vim.keymap.set("n", "<leader>J", smart_splits.swap_buf_down, { desc = "Swap split down" })
vim.keymap.set("n", "<leader>K", smart_splits.swap_buf_up, { desc = "Swap split up" })
vim.keymap.set("n", "<leader>L", smart_splits.swap_buf_right, { desc = "Swap split right" })

require("yazi").setup({
  open_for_directories = true,
  floating_window_scaling_factor = 1,
  yazi_floating_window_border = "none",
  hooks = {
    yazi_opened = function(_, buffer)
      vim.keymap.set({ "n", "t" }, "<Esc>", function()
        local job = vim.bo[buffer].channel

        if job > 0 then
          vim.fn.jobstop(job)
        end
      end, { buffer = buffer, desc = "Close Yazi", nowait = true })
    end,
  },
})

require("gitsigns").setup({})

require("diffview").setup({
  keymaps = {
    view = {
      { "n", "<Esc>", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
    },
    file_panel = {
      { "n", "<Esc>", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
    },
    file_history_panel = {
      { "n", "<Esc>", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "DiffviewFiles",
  callback = function(event)
    local actions = require("diffview.actions")
    local opts = { buffer = event.buf, nowait = true }

    vim.keymap.set("n", "s", actions.toggle_stage_entry, opts)
    vim.keymap.set("n", "S", actions.stage_all, opts)
    vim.keymap.set("n", "U", actions.unstage_all, opts)
    vim.keymap.set("n", "X", actions.restore_entry, opts)
  end,
})

require("neogit").setup({
  integrations = {
    diffview = true,
  },
  mappings = {
    status = {
      ["<Esc>"] = "Close",
    },
  },
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("neogit.lib.hl").setup(require("neogit.config").values)
  end,
})

require("grug-far").setup({
  windowCreationCommand = "leftabove vsplit",
  openTargetWindow = {
    preferredLocation = "right",
  },
  prefills = {
    flags = "--fixed-strings",
  },
})

local function setup_grug_far_highlights()
  require("grug-far.highlights").setup()
end

setup_grug_far_highlights()

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = setup_grug_far_highlights,
})

vim.api.nvim_create_autocmd("BufLeave", {
  callback = function(event)
    if vim.bo[event.buf].filetype == "grug-far" then
      vim.schedule(function()
        vim.cmd("stopinsert")
      end)
    end
  end,
})

require("snacks").setup({
  explorer = { enabled = true },
  picker = {
    enabled = true,
    sources = {
      explorer = {
        win = {
          input = {
            keys = {
              ["<C-b>"] = { toggle_snacks_explorer, mode = { "n", "i" } },
              ["<C-Right>"] = { focus_snacks_editor, mode = { "n", "i" } },
            },
          },
          list = {
            keys = {
              ["<C-b>"] = toggle_snacks_explorer,
              ["<C-Right>"] = focus_snacks_editor,
            },
          },
        },
      },
    },
    win = {
      input = {
        keys = {
          ["<Esc>"] = { "close", mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<Esc>"] = "close",
        },
      },
    },
  },
})

require("bufferline").setup({
  options = {
    show_tab_indicators = false,
    show_close_icon = false,
  },
})
