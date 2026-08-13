-- Git signs, scrollbar markers, and full-screen LazyGit UI.

local gitsigns = require("gitsigns")

local function navigate_hunk(direction)
	return function()
		if vim.wo.diff then
			vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
			return
		end

		gitsigns.nav_hunk(direction)
	end
end

gitsigns.setup({
	on_attach = function(buffer)
		local opts = { buffer = buffer }
		vim.keymap.set("n", "]h", navigate_hunk("next"), vim.tbl_extend("force", opts, { desc = "Next Git hunk" }))
		vim.keymap.set("n", "[h", navigate_hunk("prev"), vim.tbl_extend("force", opts, { desc = "Previous Git hunk" }))
		vim.keymap.set("n", "<leader>gs", gitsigns.stage_hunk, vim.tbl_extend("force", opts, { desc = "Stage / unstage hunk" }))
		vim.keymap.set("n", "<leader>gr", gitsigns.reset_hunk, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
		vim.keymap.set("x", "<leader>gs", function()
			gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, vim.tbl_extend("force", opts, { desc = "Stage selected hunks" }))
		vim.keymap.set("x", "<leader>gr", function()
			gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, vim.tbl_extend("force", opts, { desc = "Reset selected hunks" }))
		vim.keymap.set("n", "<leader>gp", gitsigns.preview_hunk, vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
		vim.keymap.set("n", "<leader>gb", gitsigns.blame_line, vim.tbl_extend("force", opts, { desc = "Blame line" }))
	end,
})

require("scrollbar").setup({
	hide_if_all_visible = true,
})
require("scrollbar.handlers.gitsigns").setup()

vim.g.lazygit_floating_window_scaling_factor = 1
vim.g.lazygit_floating_window_border_chars = { "", "", "", "", "", "", "", "" }
vim.g.lazygit_floating_window_winblend = 0
