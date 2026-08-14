-- Leader keys and shared editor actions.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Space>", "<Nop>", {
	silent = true,
})
local which_key = require("which-key")

which_key.setup({
	preset = "modern",
	delay = 150,
	icons = {
		rules = {
			{ pattern = "close", icon = "󰅖", color = "red" },
			{ pattern = "equalize", icon = "󰕭", color = "blue" },
			{ pattern = "split", icon = "", color = "blue" },
			{ pattern = "sidebar", icon = "󰙅", color = "cyan" },
			{ pattern = "color", icon = "󰏘", color = "purple" },
			{ pattern = "language", icon = "󰘦", color = "orange" },
			{ pattern = "test", icon = "󰙨", color = "green" },
			{ pattern = "task", icon = "󰑮", color = "orange" },
			{ pattern = "yank", icon = "󰆏", color = "yellow" },
			{ pattern = "save", icon = "󰆓", color = "azure" },
			{ pattern = "delete", icon = "󰆴", color = "red" },
			{ pattern = "definition", icon = "󰊕", color = "cyan" },
			{ pattern = "declaration", icon = "󰙠", color = "cyan" },
			{ pattern = "symbol", icon = "󰘦", color = "orange" },
			{ pattern = "rename", icon = "󰑕", color = "orange" },
			{ pattern = "call", icon = "󰏻", color = "cyan" },
			{ pattern = "hover", icon = "󰋼", color = "blue" },
			{ pattern = "hunk", icon = "󰊢", color = "orange" },
			{ pattern = "blame", icon = "󰊢", color = "yellow" },
			{ pattern = "restore", icon = "󰦛", color = "azure" },
			{ pattern = "run", icon = "󰐊", color = "green" },
			{ pattern = "stop", icon = "󰓛", color = "red" },
			{ pattern = "output", icon = "󰆍", color = "cyan" },
			{ pattern = "breakpoint", icon = "", color = "red" },
			{ pattern = "step", icon = "󰆹", color = "blue" },
			{ pattern = "previous", icon = "󰒮", color = "blue" },
			{ pattern = "next", icon = "󰒭", color = "blue" },
		},
	},
	triggers = {
		{ "<leader>", mode = { "n", "x", "s", "o" } },
	},
})

local M = {}

local sidebar_editor_window

function M.focus_sidebar_editor()
	if
		sidebar_editor_window
		and vim.api.nvim_win_is_valid(sidebar_editor_window)
		and vim.api.nvim_win_get_tabpage(sidebar_editor_window) == vim.api.nvim_get_current_tabpage()
	then
		vim.api.nvim_set_current_win(sidebar_editor_window)
		return
	end

	vim.cmd("wincmd l")
end

function M.close_grug_far()
	local instances = require("grug-far.instances")
	local instance = instances.get_instance()

	while instance do
		instance:close()
		instance = instances.get_instance()
	end
end

function M.close_sidebar()
	require("nvim-tree.api").tree.close()
	vim.schedule(M.focus_sidebar_editor)
end

function M.focus_sidebar()
	M.close_grug_far()

	if vim.bo.filetype ~= "NvimTree" then
		sidebar_editor_window = vim.api.nvim_get_current_win()
	end

	local tree = require("nvim-tree.api").tree
	if not tree.is_visible() then
		tree.open({ find_file = true, focus = true })
		return
	end

	tree.focus()
end

function M.toggle_sidebar()
	if require("nvim-tree.api").tree.is_visible() then
		M.close_sidebar()
		return
	end

	M.focus_sidebar()
end

function M.focus_grug_far()
	local tree = require("nvim-tree.api").tree
	if tree.is_visible() then
		M.focus_sidebar_editor()
		tree.close()
	end

	local instances = require("grug-far.instances")
	local instance = instances.get_instance()
	if instance and instance:is_open() then
		instance:open()
		return
	end

	while instance do
		instance:close()
		instance = instances.get_instance()
	end

	vim.cmd("GrugFar")
end

which_key.add({
	{
		"<leader><leader>",
		function()
			Snacks.picker.files()
		end,
		desc = "Find files",
	},
	{ "<leader>e", M.focus_sidebar, desc = "Focus sidebar" },
	{ "<C-n>", M.toggle_sidebar, desc = "Toggle sidebar" },
	{ "<leader>r", M.focus_grug_far, desc = "Search and replace" },
	{ "<leader>b", group = "Buffers" },
	{ "<leader>f", "<cmd>Yazi<cr>", desc = "File explorer" },
	{ "<leader>v", "<cmd>vsplit<cr>", desc = "Vertical split" },
	{ "<leader>h", "<cmd>split<cr>", desc = "Horizontal split" },
	{ "<leader>c", "<cmd>close<cr>", desc = "Close split" },
	{ "<leader>o", "<C-w>o", desc = "Close other splits" },
	{ "<leader>=", "<C-w>=", desc = "Equalize splits" },
	{ "<leader>g", group = "Git" },
	{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
	{
		"<leader>gf",
		function()
			Snacks.picker.git_log_file()
		end,
		desc = "File history",
	},
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
					M.focus_sidebar_editor()
					trouble.open("git_hunks")
				end)
			end)
		end,
		desc = "Toggle changed hunks",
	},
	{
		"<leader>s",
		function()
			if vim.bo.filetype == "NvimTree" then
				M.focus_sidebar_editor()
			end

			require("telescope.builtin").live_grep()
		end,
		desc = "Search file contents",
	},
	{ "<leader>l", group = "Language" },
	{ "<leader>d", group = "Diagnostics / debug" },
	{ "<leader>t", group = "Test / tasks" },
	{ "<leader>S", group = "Sessions" },
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
	{ "<leader>q", "<cmd>confirm qall<cr>", desc = "Quit Neovim" },
}, { mode = "n" })

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

vim.keymap.set("n", "<C-c>", close_current_buffer, { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bd", close_current_buffer, { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bD", function()
	Snacks.bufdelete.all()
end, { desc = "Delete all buffers" })
vim.keymap.set("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<C-s>", "<cmd>write<cr>", { desc = "Save buffer" })
vim.keymap.set("i", "<C-s>", "<cmd>write<cr>", { desc = "Save buffer" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", {
	desc = "Clear search highlighting",
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
