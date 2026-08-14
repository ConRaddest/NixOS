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
	keymaps = {
		close = false,
	},
})

local function setup_grug_far_highlights()
	require("grug-far.highlights").setup()
end

setup_grug_far_highlights()

local function setup_grug_far_window(buffer)
	if vim.bo[buffer].filetype ~= "grug-far" then
		return
	end

	vim.bo[buffer].buflisted = false
	vim.bo[buffer].bufhidden = "hide"

	local tree = require("nvim-tree.api").tree
	if tree.is_visible() then
		tree.close()
	end

	local window = vim.fn.bufwinid(buffer)
	if window == -1 then
		return
	end

	local editor_window = vim.api.nvim_win_call(window, function()
		return vim.fn.win_getid(vim.fn.winnr("l"))
	end)

	vim.keymap.set({ "n", "i" }, "<C-c>", function()
		local instance = require("grug-far.instances").get_instance(buffer)
		if instance then
			instance:hide()
		end

		vim.schedule(function()
			if vim.api.nvim_win_is_valid(editor_window) then
				vim.api.nvim_set_current_win(editor_window)
			end
		end)
	end, { buffer = buffer, desc = "Hide search and replace", nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		if vim.api.nvim_win_is_valid(editor_window) then
			vim.api.nvim_set_current_win(editor_window)
		end
	end, { buffer = buffer, desc = "Focus editor", nowait = true })

	vim.schedule(function()
		if not vim.api.nvim_win_is_valid(window) then
			return
		end

		vim.api.nvim_set_current_win(window)
		vim.api.nvim_win_set_width(window, vim.g.side_panel_width)
		vim.wo[window].winfixwidth = true
		vim.wo[window].winhighlight = table.concat({
			"Normal:NormalFloat",
			"NormalNC:NormalFloat",
			"SignColumn:NormalFloat",
			"EndOfBuffer:NormalFloat",
		}, ",")
	end)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "grug-far",
	callback = function(event)
		setup_grug_far_window(event.buf)
	end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
	callback = function(event)
		setup_grug_far_window(event.buf)
	end,
})

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
