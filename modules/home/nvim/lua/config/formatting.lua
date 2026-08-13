-- Automatic formatting and linting.

-- Formatting and linting
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		nix = { "nixfmt" },
		python = { "ruff_format" },
		sh = { "shfmt" },
		bash = { "shfmt" },
		cs = { "csharpier" },
		javascript = { "tailwind_class_stacker" },
		javascriptreact = { "tailwind_class_stacker" },
		typescript = { "tailwind_class_stacker" },
		typescriptreact = { "tailwind_class_stacker" },
		css = { "prettierd" },
		html = { "prettierd" },
		json = { "prettierd" },
		jsonc = { "prettierd" },
		markdown = { "prettierd" },
	},
	formatters = {
		tailwind_class_stacker = {
			command = "node",
			args = function(_, context)
				return {
					vim.fn.expand("~/Dev/tailwind-class-stacker/cli.js"),
					context.filename,
				}
			end,
			stdin = true,
		},
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
