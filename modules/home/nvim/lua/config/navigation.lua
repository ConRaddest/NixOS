-- Split navigation, resizing, and file navigation.

local smart_splits = require("smart-splits")

smart_splits.setup({
	at_edge = "stop",
	default_amount = 3,
})

vim.keymap.set("n", "<M-Left>", smart_splits.resize_left, { desc = "Resize split left" })
vim.keymap.set("n", "<M-Down>", smart_splits.resize_down, { desc = "Resize split down" })
vim.keymap.set("n", "<M-Up>", smart_splits.resize_up, { desc = "Resize split up" })
vim.keymap.set("n", "<M-Right>", smart_splits.resize_right, { desc = "Resize split right" })

vim.keymap.set("", "<leader>H", smart_splits.swap_buf_left, { desc = "Swap split left" })
vim.keymap.set("", "<leader>J", smart_splits.swap_buf_down, { desc = "Swap split down" })
vim.keymap.set("", "<leader>K", smart_splits.swap_buf_up, { desc = "Swap split up" })
vim.keymap.set("", "<leader>L", smart_splits.swap_buf_right, { desc = "Swap split right" })

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
	floating_window_scaling_factor = 0.9,
	yazi_floating_window_border = "rounded",
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

local function setup_yazi_highlights()
	vim.api.nvim_set_hl(0, "YaziFloat", { link = "NormalFloat" })
end

setup_yazi_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = setup_yazi_highlights,
})
