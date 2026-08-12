-- Show hexadecimal color values using their represented color.

local ccc = require("ccc")

ccc.setup({
	mappings = {
		["<Esc>"] = ccc.mapping.quit,
	},
})

require("colorizer").setup({
	filetypes = { "*" },
	options = {
		parsers = {
			names = { enable = false },
			hex = {
				default = false,
				rrggbb = true,
			},
		},
		display = {
			mode = "background",
		},
	},
})
