-- Colorscheme and theme-specific highlights.

require("tokyonight").setup({
	style = "night",
})
vim.cmd.colorscheme("tokyonight")

vim.opt.fillchars:append({
	vert = "│",
	diff = " ",
})

local function visible_split_borders()
	vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#414868", bg = "NONE" })
end

visible_split_borders()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = visible_split_borders,
})
