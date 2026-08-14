-- Diagnostic display, navigation, and Trouble lists.

vim.diagnostic.config({
	severity_sort = true,
	signs = true,
	underline = true,
	update_in_insert = true,
	virtual_text = { spacing = 2, source = "if_many" },
	float = { border = "rounded", source = true },
})

vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>lf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
vim.keymap.set("n", "<leader>dx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>dX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Line diagnostic" })

require("trouble").setup({
	modes = {
		git_hunks = {
			mode = "qflist",
			win = {
				type = "split",
				relative = "win",
				position = "bottom",
				size = 12,
			},
		},
	},
})
