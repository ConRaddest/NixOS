-- Split navigation, resizing, and file navigation.

local smart_splits = require("smart-splits")

smart_splits.setup({
	at_edge = "stop",
	default_amount = 3,
})

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
	change_neovim_cwd_on_close = true,
	open_file_function = function(chosen_file)
		if vim.fn.isdirectory(chosen_file) == 1 then
			vim.cmd.cd(chosen_file)
			return
		end

		require("yazi.openers").open_file(chosen_file)
	end,
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
