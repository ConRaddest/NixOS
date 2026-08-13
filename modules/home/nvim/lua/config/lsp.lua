-- Language server configuration and buffer-local actions.

-- Language servers
require("lazydev").setup({})

vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			hint = { arrayIndex = "Disable" },
			runtime = {
				version = "LuaJIT",
				path = { "lua/?.lua", "lua/?/init.lua" },
			},
			diagnostics = { globals = { "vim", "Snacks", "hl", "require" } },
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

-- Keep health checks and attachment behavior limited to filetypes used here.
-- Upstream configs include framework-specific aliases that Neovim does not
-- recognize without their corresponding plugins.
vim.lsp.config("glsl_analyzer", {
	filetypes = { "glsl" },
})

vim.lsp.config("qmlls", {
	filetypes = { "qml" },
})

vim.lsp.config("tailwindcss", {
	filetypes = {
		"css",
		"html",
		"javascript",
		"javascriptreact",
		"markdown",
		"typescript",
		"typescriptreact",
	},
})

vim.lsp.config("yamlls", {
	filetypes = { "yaml" },
})

vim.lsp.enable({
	"nixd",
	"lua_ls",
	"bashls",
	"ts_ls",
	"eslint",
	"glsl_analyzer",
	"html",
	"cssls",
	"jsonls",
	"yamlls",
	"clangd",
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
		-- Keep Neovim defaults: grr references, gri implementation, grn rename, gra code action.
		vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))

		vim.keymap.set(
			{ "n", "x" },
			"<leader>ca",
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
		vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Type definition" }))
		vim.keymap.set("n", "<leader>li", vim.lsp.buf.incoming_calls, vim.tbl_extend("force", opts, { desc = "Incoming calls" }))
		vim.keymap.set("n", "<leader>lo", vim.lsp.buf.outgoing_calls, vim.tbl_extend("force", opts, { desc = "Outgoing calls" }))

		if client and client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
		end

		-- nixd advertises document highlights but errors on nodes without variables.
		if client and client.name ~= "nixd" and client:supports_method("textDocument/documentHighlight") then
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
