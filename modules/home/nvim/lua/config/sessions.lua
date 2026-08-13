-- Persist project sessions without dedicated keymaps.

local persistence = require("persistence")

persistence.setup({})

vim.keymap.set("n", "<leader>Sr", function()
	persistence.load()
end, { desc = "Restore directory session" })
vim.keymap.set("n", "<leader>Sl", function()
	persistence.load({ last = true })
end, { desc = "Restore last session" })
vim.keymap.set("n", "<leader>Ss", persistence.select, { desc = "Select session" })
vim.keymap.set("n", "<leader>SS", persistence.stop, { desc = "Stop session saving" })
