-- Project session persistence and restore controls.

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
