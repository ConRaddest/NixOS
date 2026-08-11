vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Space>", "<Nop>", {
	silent = true,
})

require("tokyonight").setup({
	style = "night",
})
vim.cmd.colorscheme("tokyonight")

vim.opt.fillchars:append({
	vert = "│",
	diff = " ",
})

local function visible_split_borders()
	vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#414868", bg = "NONE" })
end

visible_split_borders()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = visible_split_borders,
})

-- Plain-text note theme. Row color depends only on two-space indentation depth.
local function setup_note_highlights()
	vim.api.nvim_set_hl(0, "NoteIndent0", { fg = "#7aa2f7", bold = true })
	vim.api.nvim_set_hl(0, "NoteIndent1", { fg = "#bb9af7", bold = true })
	vim.api.nvim_set_hl(0, "NoteIndent2", { fg = "#7dcfff" })
	vim.api.nvim_set_hl(0, "NoteIndent3", { fg = "#e0af68" })
	vim.api.nvim_set_hl(0, "NoteIndent4", { fg = "#9ece6a" })
	vim.api.nvim_set_hl(0, "NoteIndent5", { fg = "#c0caf5" })
	vim.api.nvim_set_hl(0, "NoteTag", { fg = "#f7768e", bold = true })
end

local function setup_note_syntax(buffer)
	vim.api.nvim_buf_call(buffer, function()
		vim.cmd([[silent! syntax clear NoteHeading1 NoteHeading2 NoteHeading3 NoteArrow NoteLetter NoteBullet]])
		vim.cmd([[syntax match NoteTag /\<[A-Z][A-Z0-9_-]*:.*$/ contained]])
		vim.cmd([[syntax match NoteIndent0 /^\S.*$/ contains=NoteTag]])
		vim.cmd([[syntax match NoteIndent1 /^  \S.*$/ contains=NoteTag]])
		vim.cmd([[syntax match NoteIndent2 /^    \S.*$/ contains=NoteTag]])
		vim.cmd([[syntax match NoteIndent3 /^      \S.*$/ contains=NoteTag]])
		vim.cmd([[syntax match NoteIndent4 /^        \S.*$/ contains=NoteTag]])
		vim.cmd([[syntax match NoteIndent5 /^          \s*\S.*$/ contains=NoteTag]])
	end)
end

setup_note_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = setup_note_highlights,
})
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufWinEnter" }, {
	pattern = "*.txt",
	callback = function(event)
		setup_note_syntax(event.buf)
	end,
})

local which_key = require("which-key")

which_key.setup({
	preset = "modern",
	delay = 150,
})

local snacks_editor_window

local function focus_snacks_editor()
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

local function toggle_snacks_explorer()
	local explorer = Snacks.picker.get({ source = "explorer" })[1]

	if explorer then
		explorer:close()
		vim.schedule(focus_snacks_editor)
		return
	end

	snacks_editor_window = vim.api.nvim_get_current_win()
	Snacks.explorer({ focus = true })
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
		toggle_snacks_explorer,
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
	{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Review changes" },
	{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
	{ "<leader>s", group = "Search" },
	{ "<leader>l", group = "Language" },
	{ "<leader>d", group = "Diagnostics" },
	{ "<leader>t", group = "Test / tasks" },
	{ "<leader>q", group = "Session" },
	{ "<leader>y", group = "Yank" },
	{
		"<leader>yp",
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
		"<leader>sr",
		function()
			if vim.bo.filetype:match("^snacks_picker") then
				focus_snacks_editor()
			end

			vim.cmd("GrugFar")
		end,
		desc = "Search and replace",
	},
	{ "<C-q>", "<cmd>confirm qall<cr>", desc = "Quit Neovim" },
	{ "<leader>w", "<cmd>write<cr>", desc = "Save" },
	{ "<C-s>", save_current_buffer, desc = "Save" },
})

vim.keymap.set("n", "<C-c>", function()
	local split_count = 0

	for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_config(window).relative == "" then
			split_count = split_count + 1
		end
	end

	if split_count > 1 then
		vim.api.nvim_win_close(vim.api.nvim_get_current_win(), false)
		return
	end

	Snacks.bufdelete()
end, {
	desc = "Close split or buffer",
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

-- Editor behavior
vim.opt.cursorline = true
vim.opt.cursorlineopt = "both"
vim.opt.number = true
vim.opt.statuscolumn = "  %s%l  "
vim.opt.relativenumber = false
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.confirm = true
vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python" },
	callback = function()
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "make" },
	callback = function()
		vim.bo.expandtab = false
	end,
})

local smart_splits = require("smart-splits")

smart_splits.setup({
	at_edge = "stop",
	default_amount = 3,
})

vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left, { desc = "Focus left split" })
vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down, { desc = "Focus lower split" })
vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up, { desc = "Focus upper split" })
vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right, { desc = "Focus right split" })
vim.keymap.set("n", "<C-Left>", smart_splits.move_cursor_left, { desc = "Focus left split" })
vim.keymap.set("n", "<C-Down>", smart_splits.move_cursor_down, { desc = "Focus lower split" })
vim.keymap.set("n", "<C-Up>", smart_splits.move_cursor_up, { desc = "Focus upper split" })
vim.keymap.set("n", "<C-Right>", smart_splits.move_cursor_right, { desc = "Focus right split" })

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

require("gitsigns").setup({})

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

vim.api.nvim_create_autocmd("FileType", {
	pattern = "DiffviewFiles",
	callback = function(event)
		local actions = require("diffview.actions")
		local opts = { buffer = event.buf, nowait = true }

		vim.keymap.set("n", "s", actions.toggle_stage_entry, opts)
		vim.keymap.set("n", "S", actions.stage_all, opts)
		vim.keymap.set("n", "U", actions.unstage_all, opts)
		vim.keymap.set("n", "X", actions.restore_entry, opts)
	end,
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

require("snacks").setup({
	explorer = { enabled = true },
	indent = {
		enabled = true,
		indent = {
			enabled = true,
			char = "│",
		},
		scope = { enabled = false },
		chunk = { enabled = false },
	},
	picker = {
		enabled = true,
		sources = {
			explorer = {
				win = {
					input = {
						keys = {
							["<C-b>"] = { toggle_snacks_explorer, mode = { "n", "i" } },
							["<C-Right>"] = { focus_snacks_editor, mode = { "n", "i" } },
						},
					},
					list = {
						keys = {
							["<C-b>"] = toggle_snacks_explorer,
							["<C-Right>"] = focus_snacks_editor,
						},
					},
				},
			},
		},
		win = {
			input = {
				keys = {
					["<Esc>"] = { "close", mode = { "n", "i" } },
				},
			},
			list = {
				keys = {
					["<Esc>"] = "close",
				},
			},
		},
	},
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		snacks_editor_window = vim.api.nvim_get_current_win()
		Snacks.explorer({ focus = true })
	end,
})

require("bufferline").setup({
	options = {
		show_tab_indicators = false,
		show_close_icon = false,
	},
})

-- Syntax and structural context
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"bash",
		"c",
		"cs",
		"css",
		"html",
		"javascript",
		"javascriptreact",
		"json",
		"lua",
		"markdown",
		"nix",
		"python",
		"qml",
		"typescript",
		"typescriptreact",
		"vim",
		"yaml",
	},
	callback = function()
		vim.treesitter.start()
	end,
})

require("treesitter-context").setup({
	max_lines = 4,
	multiline_threshold = 1,
})

require("nvim-ts-autotag").setup({})

require("nvim-autopairs").setup({
	check_ts = true,
	map_cr = false,
})

-- Completion
require("blink.cmp").setup({
	keymap = {
		preset = "enter",
		["<S-Tab>"] = {
			"snippet_backward",
			function()
				vim.api.nvim_feedkeys(vim.keycode("<C-d>"), "n", false)
				return true
			end,
		},
	},
	appearance = {
		nerd_font_variant = "mono",
	},
	completion = {
		documentation = { auto_show = true, auto_show_delay_ms = 50 },
		list = { selection = { preselect = false, auto_insert = false } },
		accept = {
			auto_brackets = {
				semantic_token_resolution = {
					blocked_filetypes = { "javascriptreact", "typescriptreact" },
				},
			},
		},
	},
	signature = { enabled = true },
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
		providers = {
			snippets = {
				opts = {
					-- Keep language snippets, exclude friendly-snippets/global.json.
					global_snippets = {},
				},
			},
		},
	},
})

-- Language servers
vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = { "lua/?.lua", "lua/?/init.lua" },
			},
			diagnostics = { globals = { "vim", "Snacks", "hl" } },
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME },
			},
		},
	},
})

vim.lsp.config("nixd", {
	settings = {
		nixd = {
			formatting = { command = { "nixfmt" } },
		},
	},
})

vim.lsp.enable({
	"nixd",
	"lua_ls",
	"bashls",
	"ts_ls",
	"eslint",
	"html",
	"cssls",
	"jsonls",
	"tailwindcss",
	"emmet_language_server",
	"roslyn_ls",
	"qmlls",
	"basedpyright",
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local opts = { buffer = event.buf }
		local client = vim.lsp.get_client_by_id(event.data.client_id)

		vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Definition" }))
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Declaration" }))
		vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
		vim.keymap.set(
			"n",
			"gi",
			vim.lsp.buf.implementation,
			vim.tbl_extend("force", opts, { desc = "Implementation" })
		)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))

		vim.keymap.set(
			"n",
			"<leader>la",
			vim.lsp.buf.code_action,
			vim.tbl_extend("force", opts, { desc = "Code action" })
		)
		vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
		vim.keymap.set(
			"n",
			"<leader>ls",
			vim.lsp.buf.document_symbol,
			vim.tbl_extend("force", opts, { desc = "Document symbols" })
		)
		vim.keymap.set(
			"n",
			"<leader>lS",
			vim.lsp.buf.workspace_symbol,
			vim.tbl_extend("force", opts, { desc = "Workspace symbols" })
		)

		if client and client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
		end

		if client and client:supports_method("textDocument/documentHighlight") then
			local group = vim.api.nvim_create_augroup("lsp-highlight-" .. event.buf, { clear = true })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				group = group,
				buffer = event.buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				group = group,
				buffer = event.buf,
				callback = vim.lsp.buf.clear_references,
			})
		end
	end,
})

-- Formatting and linting
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		nix = { "nixfmt" },
		python = { "ruff_format" },
		sh = { "shfmt" },
		bash = { "shfmt" },
		cs = { "csharpier" },
		javascript = { "prettierd" },
		javascriptreact = { "prettierd" },
		typescript = { "prettierd" },
		typescriptreact = { "prettierd" },
		css = { "prettierd" },
		html = { "prettierd" },
		json = { "prettierd" },
		jsonc = { "prettierd" },
		markdown = { "prettierd" },
	},
	format_on_save = {
		timeout_ms = 1000,
		lsp_format = "fallback",
	},
})

require("lint").linters_by_ft = {
	python = { "ruff" },
	sh = { "shellcheck" },
	bash = { "shellcheck" },
	nix = { "statix", "deadnix" },
}

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	callback = function()
		require("lint").try_lint()
	end,
})

vim.diagnostic.config({
	severity_sort = true,
	signs = true,
	underline = true,
	update_in_insert = false,
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

require("trouble").setup({})

-- Tests and project tasks
local neotest = require("neotest")

neotest.setup({
	adapters = {
		require("neotest-python")({}),
		require("neotest-dotnet")({ discovery_root = "project" }),
	},
})

vim.keymap.set("n", "<leader>tn", function()
	neotest.run.run()
end, { desc = "Run nearest test" })
vim.keymap.set("n", "<leader>tf", function()
	neotest.run.run(vim.fn.expand("%"))
end, { desc = "Run test file" })
vim.keymap.set("n", "<leader>ts", neotest.summary.toggle, { desc = "Test summary" })
require("overseer").setup({})
vim.keymap.set("n", "<leader>tr", "<cmd>OverseerRun<cr>", { desc = "Run task" })
vim.keymap.set("n", "<leader>tt", "<cmd>OverseerToggle<cr>", { desc = "Task list" })

-- Project sessions
require("persistence").setup({})
vim.keymap.set("n", "<leader>qs", function()
	require("persistence").load()
end, { desc = "Restore session" })
vim.keymap.set("n", "<leader>ql", function()
	require("persistence").load({ last = true })
end, { desc = "Restore last session" })
vim.keymap.set("n", "<leader>qd", function()
	require("persistence").stop()
end, { desc = "Do not save session" })
