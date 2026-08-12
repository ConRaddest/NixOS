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

local function save_current_buffer()
	if vim.api.nvim_buf_get_name(0) ~= "" then
		vim.cmd("write")
		return
	end

	local path = vim.fn.input("Save as: ", vim.fn.getcwd() .. "/", "file")

	if path ~= "" then
		vim.cmd("write " .. vim.fn.fnameescape(path))
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
	{
		"<C-b>",
		M.toggle_snacks_explorer,
		desc = "Snacks explorer",
	},
	{ "<M-Left>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
	{ "<M-Right>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
	{ "<leader>v", "<cmd>vsplit<cr>", desc = "Vertical split" },
	{ "<leader>h", "<cmd>split<cr>", desc = "Horizontal split" },
	{ "<leader>c", "<cmd>close<cr>", desc = "Close split" },
	{ "<leader>o", "<C-w>o", desc = "Close other splits" },
	{ "<leader>=", "<C-w>=", desc = "Equalize splits" },
	{ "<leader>e", "<cmd>Yazi<cr>", desc = "File explorer" },
	{ "<leader>g", group = "Git" },
	{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Git status" },
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
	{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Review changes" },
	{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
	{ "<leader>s", group = "Search" },
	{ "<leader>l", group = "Language" },
	{ "<leader>d", group = "Diagnostics" },
	{ "<leader>t", group = "Test / tasks" },
	{ "<leader>q", group = "Session" },
	{ "<leader>y", group = "Yank" },
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
		"<leader>sr",
		function()
			if vim.bo.filetype:match("^snacks_picker") then
				M.focus_snacks_editor()
			end

			vim.cmd("GrugFar")
		end,
		desc = "Search and replace",
	},
	{ "<C-q>", "<cmd>confirm qall<cr>", desc = "Quit Neovim" },
	{ "<leader>w", "<cmd>write<cr>", desc = "Save" },
	{ "<C-s>", save_current_buffer, desc = "Save" },
})

vim.keymap.set({ "n", "i" }, "<C-/>", M.focus_snacks_explorer_input, {
	desc = "Focus explorer search",
})

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
	nowait = true,
})
vim.keymap.set("n", "<C-w>", close_current_buffer, {
	desc = "Close buffer",
	nowait = true,
})

vim.keymap.set("i", "<C-s>", function()
	vim.cmd("stopinsert")
	vim.schedule(save_current_buffer)
end, {
	desc = "Exit insert mode and save",
})

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", {
	desc = "Clear search highlighting",
})

vim.keymap.set("n", "<C-f>", "/", {
	desc = "Find text",
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

vim.keymap.set("x", "<C-f>", function()
	vim.cmd("normal! y")

	local text = vim.fn.getreg('"'):gsub("\n", "\\n")
	local pattern = "\\V" .. vim.fn.escape(text, "\\")

	vim.fn.setreg("/", pattern)
	vim.opt.hlsearch = true
	vim.cmd("normal! n")
end, {
	desc = "Search selected text",
})

-- Let UI module record active editor before explorer takes focus.
return M
