-- Explorer, picker, indentation guides, and buffer tabs.

local keymaps = require("config.keymaps")

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
				-- Keep preview hidden until explicitly toggled with Alt+p.
				hidden = true,
				layout = { preset = "sidebar", preview = { enabled = false, main = true } },
				win = {
					input = {
						keys = {
							["<Esc>"] = { "focus_list", mode = { "n", "i" } },
							["<C-b>"] = { keymaps.toggle_snacks_explorer, mode = { "n", "i" } },
							["<M-p>"] = { "toggle_preview", mode = { "n", "i" } },
						},
					},
					list = {
						keys = {
							["<Esc>"] = keymaps.focus_snacks_editor,
							["<C-b>"] = keymaps.toggle_snacks_explorer,
							["<M-p>"] = "toggle_preview",
							["P"] = false,
						},
					},
				},
			},
			files = {
				hidden = true,
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
		Snacks.explorer({ focus = true })
	end,
})

require("bufferline").setup({
	options = {
		show_tab_indicators = false,
		show_close_icon = false,
		custom_filter = function(buffer)
			return vim.api.nvim_buf_get_name(buffer) ~= ""
		end,
	},
})
