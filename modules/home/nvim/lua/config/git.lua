-- Git signs, scrollbar markers, and full-screen LazyGit UI.

require("gitsigns").setup({})

require("scrollbar").setup({
	hide_if_all_visible = true,
})
require("scrollbar.handlers.gitsigns").setup()

vim.g.lazygit_floating_window_scaling_factor = 1
vim.g.lazygit_floating_window_border_chars = { "", "", "", "", "", "", "", "" }
vim.g.lazygit_floating_window_winblend = 0
