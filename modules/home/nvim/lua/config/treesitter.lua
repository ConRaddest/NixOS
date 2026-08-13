-- Syntax parsing, structural context, tags, and pairs.

-- Syntax and structural context
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"bash",
		"c",
		"cs",
		"css",
		"glsl",
		"html",
		"javascript",
		"javascriptreact",
		"json",
		"lua",
		"markdown",
		"nix",
		"python",
		"qml",
		"typescript",
		"typescriptreact",
		"vim",
		"yaml",
	},
	callback = function()
		vim.treesitter.start()
	end,
})

require("treesitter-context").setup({
	max_lines = 4,
	multiline_threshold = 1,
})

require("nvim-ts-autotag").setup({})

require("nvim-autopairs").setup({
	check_ts = true,
	map_cr = true,
})
