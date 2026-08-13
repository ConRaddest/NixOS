-- Explorer, picker, and buffer tabs.

local keymaps = require("config.keymaps")

require("snacks").setup({
	explorer = { enabled = true },
	picker = {
		enabled = true,
		sources = {
			explorer = {
				-- Keep preview hidden until explicitly toggled with Alt+p.
				ignored = true,
				layout = {
					preset = "sidebar",
					preview = { enabled = false, main = true },
					layout = { width = 0.25, min_width = 1 },
				},
				win = {
					input = {
						keys = {
							["<Esc>"] = { keymaps.focus_snacks_editor, mode = { "n", "i" } },
							["<C-c>"] = { keymaps.close_snacks_explorer, mode = { "n", "i" } },
							["<M-p>"] = { "toggle_preview", mode = { "n", "i" } },
						},
					},
					list = {
						keys = {
							["<Esc>"] = keymaps.focus_snacks_editor,
							["<C-c>"] = keymaps.close_snacks_explorer,
							["<M-p>"] = "toggle_preview",
							["P"] = false,
						},
					},
				},
			},
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

-- Put affirmative choice first for explorer move/delete confirmations.
Snacks.picker.util.confirm = function(prompt, action)
	Snacks.picker.select({ "Yes", "No" }, {
		prompt = prompt,
		snacks = {
			layout = {
				layout = { max_width = 60 },
			},
		},
	}, function(_, index)
		if index == 1 then
			action()
		end
	end)
end

require("bufferline").setup({
	options = {
		show_tab_indicators = false,
		show_close_icon = false,
		custom_filter = function(buffer)
			return vim.api.nvim_buf_get_name(buffer) ~= "" and vim.bo[buffer].filetype ~= "grug-far"
		end,
	},
})
