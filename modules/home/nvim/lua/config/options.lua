-- Core editor options and filetype-specific indentation.

-- Editor behavior
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "both"
vim.opt.number = true
vim.opt.statuscolumn = "  %s%l  "
vim.opt.relativenumber = false
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.confirm = true
vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python" },
	callback = function()
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "make" },
	callback = function()
		vim.bo.expandtab = false
	end,
})

-- Restore block indentation when insert-mode movement enters an empty block line.
vim.api.nvim_create_autocmd("CursorMovedI", {
	callback = function()
		local row = vim.api.nvim_win_get_cursor(0)[1]
		local line = vim.api.nvim_get_current_line()
		if not line:match("^%s*$") then
			return
		end

		local previous_row = vim.fn.prevnonblank(row - 1)
		local next_row = vim.fn.nextnonblank(row + 1)
		if previous_row == 0 or next_row == 0 then
			return
		end

		local previous_line = vim.fn.getline(previous_row)
		local next_line = vim.fn.getline(next_row)
		if not previous_line:match("[%{%[(]%s*$") or not next_line:match("^%s*[%}%]%)]") then
			return
		end

		local width = vim.fn.indent(next_row) + vim.fn.shiftwidth()
		local indentation
		if vim.bo.expandtab then
			indentation = string.rep(" ", width)
		else
			local tabstop = vim.bo.tabstop
			indentation = string.rep("\t", math.floor(width / tabstop)) .. string.rep(" ", width % tabstop)
		end

		if line ~= indentation then
			vim.api.nvim_set_current_line(indentation)
		end
		vim.api.nvim_win_set_cursor(0, { row, #indentation })
	end,
})
