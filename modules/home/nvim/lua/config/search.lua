-- Project-wide content search and replacement.

require("telescope").setup({
	defaults = {
		layout_strategy = "horizontal",
		layout_config = {
			width = 0.85,
			height = 0.8,
			preview_width = 0.55,
		},
	},
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
