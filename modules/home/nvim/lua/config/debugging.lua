-- Debug adapters, UI, and controls.

local dap = require("dap")
local dapui = require("dapui")

require("nvim-dap-virtual-text").setup({})
dapui.setup()

dap.adapters.python = {
	type = "executable",
	command = "debugpy-adapter",
}

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch current file",
		program = "${file}",
		pythonPath = function()
			local virtual_env = vim.env.VIRTUAL_ENV
			if virtual_env then
				return virtual_env .. "/bin/python"
			end
			return "python"
		end,
	},
}

dap.adapters.coreclr = {
	type = "executable",
	command = "netcoredbg",
	args = { "--interpreter=vscode" },
}

dap.configurations.cs = {
	{
		type = "coreclr",
		request = "launch",
		name = "Launch .NET executable",
		program = function()
			return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
		end,
	},
}

dap.listeners.before.attach.dapui = dapui.open
dap.listeners.before.launch.dapui = dapui.open
dap.listeners.before.event_terminated.dapui = dapui.close
dap.listeners.before.event_exited.dapui = dapui.close

vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Conditional breakpoint" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue / start debugger" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step over" })
vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open debug REPL" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate debugger" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle debug UI" })
