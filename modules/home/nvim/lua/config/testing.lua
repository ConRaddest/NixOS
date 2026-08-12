-- Test runners and project task controls.

-- Tests and project tasks
local neotest = require("neotest")

neotest.setup({
	adapters = {
		require("neotest-python")({}),
		require("neotest-dotnet")({ discovery_root = "project" }),
	},
})

vim.keymap.set("n", "<leader>tn", function()
	neotest.run.run()
end, { desc = "Run nearest test" })
vim.keymap.set("n", "<leader>tf", function()
	neotest.run.run(vim.fn.expand("%"))
end, { desc = "Run test file" })
vim.keymap.set("n", "<leader>ts", neotest.summary.toggle, { desc = "Test summary" })
require("overseer").setup({})
vim.keymap.set("n", "<leader>tr", "<cmd>OverseerRun<cr>", { desc = "Run task" })
vim.keymap.set("n", "<leader>tt", "<cmd>OverseerToggle<cr>", { desc = "Task list" })
