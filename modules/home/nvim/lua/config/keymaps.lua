-- Leader keys and shared editor actions.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set({ "n", "x" }, "<Space>", "<Nop>", {
	silent = true,
})
local which_key = require("which-key")

which_key.setup({
	preset = "modern",
	delay = 150,
})

local M = {}

local snacks_editor_window

function M.focus_snacks_editor()
	if
		snacks_editor_window
		and vim.api.nvim_win_is_valid(snacks_editor_window)
		and vim.api.nvim_win_get_tabpage(snacks_editor_window) == vim.api.nvim_get_current_tabpage()
	then
		vim.api.nvim_set_current_win(snacks_editor_window)
		return
	end

	vim.cmd("wincmd l")
end

function M.toggle_snacks_explorer()
	local explorer = Snacks.picker.get({ source = "explorer" })[1]

	if explorer then
		explorer:close()
		vim.schedule(M.focus_snacks_editor)
		return
	end

	snacks_editor_window = vim.api.nvim_get_current_win()
	Snacks.explorer({ focus = true })
end

function M.focus_snacks_explorer()
	local explorer = Snacks.picker.get({ source = "explorer" })[1]

	if not vim.bo.filetype:match("^snacks_picker") then
		snacks_editor_window = vim.api.nvim_get_current_win()
	end

	if not explorer then
		Snacks.explorer({ focus = true })
		explorer = Snacks.picker.get({ source = "explorer" })[1]
	end

	if explorer then
		explorer:focus("list", { show = true })
	end
end

function M.focus_snacks_explorer_input()
	local explorer = Snacks.picker.get({ source = "explorer" })[1]

	if not explorer then
		snacks_editor_window = vim.api.nvim_get_current_win()
		Snacks.explorer({ focus = true })
		explorer = Snacks.picker.get({ source = "explorer" })[1]
	end

	if explorer then
		explorer:focus("input", { show = true })
	end
end

which_key.add({
	{
		"<leader><leader>",
		function()
			Snacks.picker.files()
		end,
		desc = "Find files",
	},
	{ "<leader>e", M.focus_snacks_explorer, desc = "Focus sidebar" },
	{ "<leader>f", group = "Files" },
	{ "<leader>fe", M.toggle_snacks_explorer, desc = "Snacks explorer" },
	{ "<leader>fs", M.focus_snacks_explorer_input, desc = "Focus Snacks search" },
	{ "<leader>v", "<cmd>vsplit<cr>", desc = "Vertical split" },
	{ "<leader>h", "<cmd>split<cr>", desc = "Horizontal split" },
	{ "<leader>c", "<cmd>close<cr>", desc = "Close split" },
	{ "<leader>o", "<C-w>o", desc = "Close other splits" },
	{ "<leader>=", "<C-w>=", desc = "Equalize splits" },
	{ "<leader>fy", "<cmd>Yazi<cr>", desc = "File explorer" },
	{ "<leader>g", group = "Git" },
	{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
	{
		"<leader>gc",
		function()
			local trouble = require("trouble")

			if trouble.is_open("git_hunks") then
				trouble.close("git_hunks")
				return
			end

			require("gitsigns").setqflist("all", { open = false }, function(error)
				if error then
					vim.notify(error, vim.log.levels.ERROR)
					return
				end

				vim.schedule(function()
					M.focus_snacks_editor()
					trouble.open("git_hunks")
				end)
			end)
		end,
		desc = "Toggle changed hunks",
	},
	{ "<leader>s", group = "Search" },
	{ "<leader>l", group = "Language" },
	{ "<leader>d", group = "Diagnostics" },
	{ "<leader>t", group = "Test / tasks" },
	{ "<leader>y", group = "Yank" },
	{ "<leader>p", "<cmd>CccPick<cr>", desc = "Pick color" },
	{
		"<leader>yd",
		function()
			local buffer_path = vim.api.nvim_buf_get_name(0)
			local directory = buffer_path == "" and vim.fn.getcwd() or vim.fn.fnamemodify(buffer_path, ":p:h")

			vim.fn.setreg("+", directory)
			vim.fn.setreg('"', directory)
			vim.notify("Copied directory: " .. directory)
		end,
		desc = "Yank buffer directory",
	},
	{
		"<leader>yf",
		function()
			local buffer_path = vim.api.nvim_buf_get_name(0)

			if buffer_path == "" then
				vim.notify("Buffer has no file", vim.log.levels.WARN)
				return
			end

			local file_path = vim.fn.fnamemodify(buffer_path, ":p")

			vim.fn.setreg("+", file_path)
			vim.fn.setreg('"', file_path)
			vim.notify("Copied file path: " .. file_path)
		end,
		desc = "Yank buffer file path",
	},
	{
		"<leader>sf",
		function()
			if vim.bo.filetype:match("^snacks_picker") then
				M.focus_snacks_editor()
			end

			require("telescope.builtin").live_grep()
		end,
		desc = "Search file contents",
	},
	{
		"<leader>sb",
		function()
			local file = vim.api.nvim_buf_get_name(0)

			if file == "" then
				vim.notify("Buffer has no file", vim.log.levels.WARN)
				return
			end

			require("telescope.builtin").live_grep({
				search_dirs = { file },
				prompt_title = "Search current file",
			})
		end,
		desc = "Search current file",
	},
	{
		"<leader>sr",
		function()
			if vim.bo.filetype:match("^snacks_picker") then
				M.focus_snacks_editor()
			end

			vim.cmd("GrugFar")
		end,
		desc = "Search and replace",
	},
	{ "<leader>q", "<cmd>confirm qall<cr>", desc = "Quit Neovim" },
	{ "<leader>w", "<cmd>write<cr>", desc = "Save" },
}, { mode = { "n", "x" } })

vim.keymap.set("n", "<C-/>", "gcc", {
	desc = "Toggle comment for current line",
	remap = true,
})

vim.keymap.set("x", "<C-/>", "gc", {
	desc = "Toggle comment for selected lines",
	remap = true,
})

local function centered_page_motion(motion)
	return function()
		local keys = vim.api.nvim_replace_termcodes(motion, true, false, true)
		vim.cmd.normal({ args = { keys }, bang = true })

		if vim.fn.line("w0") == 1 then
			vim.cmd.normal({ args = { "gg" }, bang = true })
		elseif vim.fn.line("w$") == vim.fn.line("$") then
			vim.cmd.normal({ args = { "G" }, bang = true })
		else
			vim.cmd.normal({ args = { "zz" }, bang = true })
		end
	end
end

local centered_page_motions = {
	["<C-d>"] = "<C-d>",
	["<C-u>"] = "<C-u>",
	["<C-f>"] = "<C-f>",
	["<C-b>"] = "<C-b>",
	["<PageDown>"] = "<C-f>",
	["<PageUp>"] = "<C-b>",
}

for key, motion in pairs(centered_page_motions) do
	vim.keymap.set("n", key, centered_page_motion(motion), { desc = "Page with centered cursor" })
end

local function close_current_buffer()
	local buffer = vim.api.nvim_get_current_buf()

	if vim.bo[buffer].modified then
		local choice =
			vim.fn.confirm(("Save changes to %q?"):format(vim.api.nvim_buf_get_name(buffer)), "&Yes\n&No\n&Cancel")

		if choice == 0 or choice == 3 then
			return
		end

		if choice == 1 then
			vim.api.nvim_buf_call(buffer, vim.cmd.write)
		end
	end

	local buffers = require("bufferline.commands").get_elements().elements
	local next_buffer

	for index, item in ipairs(buffers) do
		if item.id == buffer then
			next_buffer = buffers[index + 1] or buffers[index - 1]
			break
		end
	end

	if next_buffer and vim.api.nvim_buf_is_valid(next_buffer.id) then
		vim.api.nvim_win_set_buf(0, next_buffer.id)
	end

	Snacks.bufdelete({ buf = buffer, force = true })
end

vim.keymap.set("n", "<C-c>", close_current_buffer, {
	desc = "Close buffer",
})

vim.keymap.set("n", "<C-s>", "<cmd>write<cr>", {
	desc = "Save buffer",
})

vim.keymap.set("i", "<C-s>", "<Esc><cmd>write<cr>", {
	desc = "Save buffer and enter normal mode",
})

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", {
	desc = "Clear search highlighting",
})

vim.keymap.set("n", "o", function()
	local current_line = vim.api.nvim_get_current_line()
	if current_line:match("%S") then
		return "o"
	end

	local current_row = vim.api.nvim_win_get_cursor(0)[1]
	local next_row = vim.fn.nextnonblank(current_row + 1)
	local reference_row = next_row > 0 and next_row or vim.fn.prevnonblank(current_row - 1)
	if reference_row == 0 then
		return "o"
	end

	local reference_line = vim.fn.getline(reference_row)
	local indentation = reference_line:match("^%s*") or ""
	local content = reference_line:sub(#indentation + 1)
	if next_row > 0 and content:match("^[%]%)}]") then
		local indent_unit = vim.bo.expandtab and string.rep(" ", vim.fn.shiftwidth()) or "\t"
		indentation = indentation .. indent_unit
	end

	return "o" .. indentation
end, {
	desc = "Open indented line",
	expr = true,
})

local function clear_selection_matches()
	if vim.w.selection_match_id then
		pcall(vim.fn.matchdelete, vim.w.selection_match_id)
		vim.w.selection_match_id = nil
	end
end

local function highlight_selection_matches()
	clear_selection_matches()

	local mode = vim.fn.mode()
	if not mode:match("^[vV\22]") then
		return
	end

	local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
	local text = table.concat(lines, "\\n")
	if text == "" or text:match("^%s+$") then
		return
	end

	local pattern = "\\V" .. vim.fn.escape(text, "\\")
	vim.w.selection_match_id = vim.fn.matchadd("Search", pattern)
end

vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
	callback = highlight_selection_matches,
})

-- Let UI module record active editor before explorer takes focus.
return M
