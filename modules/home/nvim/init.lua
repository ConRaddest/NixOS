vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("tokyonight").setup({
  style = "night",
})
vim.cmd.colorscheme("tokyonight")

local function transparent_number_column()
  vim.cmd([[
    highlight LineNr guibg=NONE ctermbg=NONE
    highlight CursorLineNr guibg=NONE ctermbg=NONE
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
  delay = 300,
})

which_key.add({
  {
    "<leader>b",
    function()
      Snacks.explorer()
    end,
    desc = "Snacks explorer",
  },
  { "<Tab>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
  { "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
  { "<leader>e", "<cmd>Yazi<cr>", desc = "File explorer" },
  { "<leader>g", group = "Git" },
  { "<leader>gg", "<cmd>Neogit<cr>", desc = "Git status" },
  { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Review changes" },
  { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
  { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
  {
    "<leader>gs",
    function()
      require("gitsigns").stage_hunk()
    end,
    desc = "Stage hunk",
  },
  {
    "<leader>gu",
    function()
      require("gitsigns").undo_stage_hunk()
    end,
    desc = "Undo staged hunk",
  },
  {
    "<leader>gr",
    function()
      require("gitsigns").reset_hunk()
    end,
    desc = "Reset hunk",
  },
  {
    "<leader>gp",
    function()
      require("gitsigns").preview_hunk()
    end,
    desc = "Preview hunk",
  },
  { "<leader>w", "<cmd>write<cr>", desc = "Save" },
  { "<C-s>", "<cmd>write<cr>", desc = "Save" },
})

vim.keymap.set("n", "<C-w>", function()
  Snacks.bufdelete()
end, {
  desc = "Close buffer",
  nowait = true,
})

vim.keymap.set("n", "<C-q>", "<cmd>quitall<cr>", {
  desc = "Quit Neovim",
  nowait = true,
})

vim.keymap.set("i", "<C-s>", "<Esc><cmd>write<cr>", {
  desc = "Exit insert mode and save",
})

-- abosulute line numbers
vim.opt.number = true
vim.opt.statuscolumn = "  %s%l  "
vim.opt.relativenumber = false
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

require("yazi").setup({
  open_for_directories = true,
  floating_window_scaling_factor = 1,
  yazi_floating_window_border = "none",
})

require("gitsigns").setup({
  on_attach = function(buffer)
    vim.keymap.set("n", "]c", function()
      require("gitsigns").nav_hunk("next")
    end, { buffer = buffer, desc = "Next Git hunk" })

    vim.keymap.set("n", "[c", function()
      require("gitsigns").nav_hunk("prev")
    end, { buffer = buffer, desc = "Previous Git hunk" })
  end,
})

require("diffview").setup({})

require("neogit").setup({
  integrations = {
    diffview = true,
  },
})

require("snacks").setup({
  explorer = { enabled = true },
  picker = { enabled = true },
})

require("bufferline").setup({})
