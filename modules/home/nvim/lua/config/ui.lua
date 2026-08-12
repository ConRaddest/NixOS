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
				-- Native main-window preview; toggle from explorer with Alt+p.
				hidden = true,
				layout = { preset = "sidebar", preview = "main" },
				actions = {
					open_preview = function(picker, item, action)
						if item and not item.dir then
							-- Confirm selected preview, list its buffer, then focus editor.
							require("snacks.explorer.actions").actions.confirm(picker, item, action)
							return
						end

						keymaps.focus_snacks_editor()
					end,
				},
				win = {
					input = {
						keys = {
							["<Esc>"] = { "focus_list", mode = { "n", "i" } },
							["<C-b>"] = { keymaps.toggle_snacks_explorer, mode = { "n", "i" } },
							["<C-Right>"] = { "open_preview", mode = { "n", "i" } },
						},
					},
					list = {
						keys = {
							["<Esc>"] = keymaps.focus_snacks_editor,
							["<C-b>"] = keymaps.toggle_snacks_explorer,
							["<C-Right>"] = "open_preview",
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

vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		if not vim.bo.filetype:match("^snacks_picker_") then
			return
		end

		local has_open_file = vim.iter(vim.fn.getbufinfo({ buflisted = 1 })):any(function(buffer)
			return buffer.name ~= ""
		end)
		if has_open_file then
			return
		end

		vim.schedule(function()
			local explorer = Snacks.picker.get({ source = "explorer" })[1]
			if explorer and explorer.layout:is_hidden("preview") then
				explorer:toggle("preview", { enable = true })
			end
		end)
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
