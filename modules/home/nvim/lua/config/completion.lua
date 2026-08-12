-- Completion menu, snippets, and signature help.

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
