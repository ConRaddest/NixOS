-- Git signs, scrollbar markers, diffs, and Git UI.

require("gitsigns").setup({})

require("scrollbar").setup({
	hide_if_all_visible = true,
})
require("scrollbar.handlers.gitsigns").setup()

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
