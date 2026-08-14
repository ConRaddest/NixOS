-- Explorer, picker, and buffer tabs.

local keymaps = require("config.keymaps")

require("snacks").setup({
	explorer = { enabled = false },
	picker = {
		enabled = true,
		sources = {
			files = {
				ignored = true,
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

vim.ui.select = Snacks.picker.select

require("nvim-tree").setup({
	disable_netrw = true,
	hijack_cursor = true,
	sync_root_with_cwd = true,
	filters = { dotfiles = false },
	update_focused_file = {
		enable = true,
		update_root = false,
	},
	actions = {
		open_file = {
			resize_window = false,
		},
	},
	view = {
		width = vim.g.side_panel_width,
		preserve_window_proportions = true,
	},
	renderer = {
		root_folder_label = false,
		highlight_git = "name",
		indent_markers = { enable = true },
		icons = {
			show = {
				git = false,
			},
			glyphs = {
				default = "󰈚",
				folder = {
					default = "",
					empty = "",
					empty_open = "",
					open = "",
					symlink = "",
				},
				git = { unmerged = "" },
			},
		},
	},
	on_attach = function(buffer)
		local api = require("nvim-tree.api")
		local preview_enabled = false
		local preview_request = 0

		local function preview_node()
			if not preview_enabled or vim.api.nvim_get_current_buf() ~= buffer then
				return
			end

			local node = api.tree.get_node_under_cursor()
			if node and node.type == "file" then
				api.node.open.preview(node, { focus = false })
			end
		end

		api.config.mappings.default_on_attach(buffer)
		vim.keymap.set("n", "<Esc>", keymaps.focus_sidebar_editor, { buffer = buffer, desc = "Focus editor" })
		vim.keymap.set("n", "<C-c>", keymaps.close_sidebar, { buffer = buffer, desc = "Close sidebar" })
		vim.keymap.set("n", "<C-p>", function()
			preview_enabled = not preview_enabled
			preview_request = preview_request + 1
			vim.notify("Sidebar preview " .. (preview_enabled and "enabled" or "disabled"))
			preview_node()
		end, { buffer = buffer, desc = "Toggle sidebar preview" })

		-- NvimTree applies its window defaults after FileType autocmds.
		vim.schedule(function()
			local window = api.tree.winid()
			if window and vim.api.nvim_win_is_valid(window) then
				vim.wo[window].statuscolumn = ""
				vim.wo[window].signcolumn = "no"
			end
		end)

		vim.api.nvim_create_autocmd("CursorMoved", {
			buffer = buffer,
			callback = function()
				if not preview_enabled then
					return
				end

				preview_request = preview_request + 1
				local request = preview_request

				vim.defer_fn(function()
					if request == preview_request then
						preview_node()
					end
				end, 100)
			end,
		})
	end,
})

require("bufferline").setup({
	options = {
		offsets = {
			{ filetype = "NvimTree", text = "", separator = true },
		},
		show_tab_indicators = false,
		show_close_icon = false,
		custom_filter = function(buffer)
			return vim.api.nvim_buf_get_name(buffer) ~= "" and vim.bo[buffer].filetype ~= "grug-far"
		end,
	},
})
