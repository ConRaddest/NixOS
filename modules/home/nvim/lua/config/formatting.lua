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
