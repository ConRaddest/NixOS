-- Test runners and project task controls.

-- Tests and project tasks
local neotest = require("neotest")

---@diagnostic disable-next-line: missing-fields
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
vim.keymap.set("n", "<leader>td", function()
	neotest.run.run({ strategy = "dap", suite = false })
end, { desc = "Debug nearest test" })
vim.keymap.set("n", "<leader>tl", neotest.run.run_last, { desc = "Run last test" })
vim.keymap.set("n", "<leader>tx", neotest.run.stop, { desc = "Stop test" })
vim.keymap.set("n", "<leader>to", neotest.output.open, { desc = "Test output" })
vim.keymap.set("n", "<leader>tO", neotest.output_panel.toggle, { desc = "Test output panel" })
vim.keymap.set("n", "<leader>ts", neotest.summary.toggle, { desc = "Test summary" })
require("overseer").setup({})
vim.keymap.set("n", "<leader>tr", "<cmd>OverseerRun<cr>", { desc = "Run task" })
vim.keymap.set("n", "<leader>tt", "<cmd>OverseerToggle<cr>", { desc = "Task list" })
