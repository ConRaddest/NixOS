-- NvChad default statusline layout, backed by system theme colors.

local M = {}
local theme = require("nix.theme")
local lsp_message = ""

local function color(name, fallback)
	return theme[name] or fallback
end

local colors = {
	background = color("background", "#1a1b26"),
	dark_background = color("dark_background", "#16161e"),
	statusline = color("dark_background", "#1d1e29"),
	light_background = color("lighter_background", "#32333e"),
	foreground = color("bright_foreground", "#c0caf5"),
	muted = color("muted", "#40486a"),
	dark_foreground = color("dark_foreground", "#565f89"),
	red = color("red", "#f7768e"),
	yellow = color("yellow", "#e0af68"),
	orange = color("orange", "#ff9e64"),
	green = color("green", "#9ece6a"),
	cyan = color("cyan", "#7dcfff"),
	blue = color("blue", "#7aa2f7"),
	magenta = color("magenta", "#bb9af7"),
	accent = color("accent", "#bb9af7"),
}

local modes = {
	["n"] = { "NORMAL", "Normal" },
	["no"] = { "NORMAL (no)", "Normal" },
	["nov"] = { "NORMAL (nov)", "Normal" },
	["noV"] = { "NORMAL (noV)", "Normal" },
	["no\22"] = { "NORMAL", "Normal" },
	["niI"] = { "NORMAL i", "Normal" },
	["niR"] = { "NORMAL r", "Normal" },
	["niV"] = { "NORMAL v", "Normal" },
	["nt"] = { "NTERMINAL", "NTerminal" },
	["ntT"] = { "NTERMINAL", "NTerminal" },
	["v"] = { "VISUAL", "Visual" },
	["vs"] = { "V-CHAR (Ctrl O)", "Visual" },
	["V"] = { "V-LINE", "Visual" },
	["Vs"] = { "V-LINE", "Visual" },
	["\22"] = { "V-BLOCK", "Visual" },
	["i"] = { "INSERT", "Insert" },
	["ic"] = { "INSERT", "Insert" },
	["ix"] = { "INSERT", "Insert" },
	["t"] = { "TERMINAL", "Terminal" },
	["R"] = { "REPLACE", "Replace" },
	["Rc"] = { "REPLACE", "Replace" },
	["Rx"] = { "REPLACE", "Replace" },
	["Rv"] = { "V-REPLACE", "Replace" },
	["Rvc"] = { "V-REPLACE", "Replace" },
	["Rvx"] = { "V-REPLACE", "Replace" },
	["s"] = { "SELECT", "Select" },
	["S"] = { "S-LINE", "Select" },
	["\19"] = { "S-BLOCK", "Select" },
	["c"] = { "COMMAND", "Command" },
	["cv"] = { "COMMAND", "Command" },
	["ce"] = { "COMMAND", "Command" },
	["cr"] = { "COMMAND", "Command" },
	["r"] = { "PROMPT", "Confirm" },
	["rm"] = { "MORE", "Confirm" },
	["r?"] = { "CONFIRM", "Confirm" },
	["x"] = { "CONFIRM", "Confirm" },
	["!"] = { "SHELL", "Terminal" },
}

local function escape(value)
	return value:gsub("%%", "%%%%")
end

local function statusline_buffer()
	return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

local function is_active_window()
	return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

local function set_highlight(name, foreground, background, bold)
	vim.api.nvim_set_hl(0, name, {
		fg = foreground,
		bg = background,
		bold = bold or false,
	})
end

local function setup_highlights()
	set_highlight("StatusLine", nil, colors.statusline)
	set_highlight("StatusLineNC", nil, colors.dark_background)
	set_highlight("St_gitIcons", colors.dark_foreground, colors.statusline, true)
	set_highlight("St_Lsp", colors.blue, colors.statusline)
	set_highlight("St_LspMsg", colors.green, colors.statusline)
	set_highlight("St_EmptySpace", colors.muted, colors.light_background)
	set_highlight("St_file", colors.foreground, colors.light_background)
	set_highlight("St_file_sep", colors.light_background, colors.statusline)
	set_highlight("St_cwd_icon", colors.light_background, colors.red)
	set_highlight("St_cwd_text", colors.foreground, colors.light_background)
	set_highlight("St_cwd_sep", colors.red, colors.statusline)
	set_highlight("St_pos_sep", colors.green, colors.light_background)
	set_highlight("St_pos_icon", colors.background, colors.green)
	set_highlight("St_pos_text", colors.green, colors.light_background)
	set_highlight("St_lspError", colors.red, colors.statusline)
	set_highlight("St_lspWarning", colors.yellow, colors.statusline)
	set_highlight("St_LspHints", colors.magenta, colors.statusline)
	set_highlight("St_LspInfo", colors.green, colors.statusline)

	local mode_colors = {
		Normal = colors.blue,
		Visual = colors.cyan,
		Insert = colors.magenta,
		Terminal = colors.green,
		NTerminal = colors.yellow,
		Replace = colors.orange,
		Confirm = colors.cyan,
		Command = colors.green,
		Select = colors.blue,
	}

	for mode, mode_color in pairs(mode_colors) do
		set_highlight("St_" .. mode .. "Mode", colors.background, mode_color, true)
		set_highlight("St_" .. mode .. "ModeSep", mode_color, colors.muted)
	end
end

local function mode_component()
	if not is_active_window() then
		return ""
	end

	local mode = modes[vim.api.nvim_get_mode().mode] or modes.n
	return ("%%#St_%sMode#  %s%%#St_%sModeSep#%%#St_EmptySpace#"):format(mode[2], mode[1], mode[2])
end

local function file_component()
	local buffer = statusline_buffer()
	local path = vim.api.nvim_buf_get_name(buffer)
	local name = path == "" and "Empty" or vim.fn.fnamemodify(path, ":t")
	local icon = "󰈚"

	if name ~= "Empty" then
		icon = require("nvim-web-devicons").get_icon(name) or icon
	end

	return ("%%#St_file# %s %s %%#St_file_sep#"):format(icon, escape(name))
end

local function git_component()
	local git = vim.b[statusline_buffer()].gitsigns_status_dict
	if not git then
		return ""
	end

	local added = git.added and git.added > 0 and ("  " .. git.added) or ""
	local changed = git.changed and git.changed > 0 and ("  " .. git.changed) or ""
	local removed = git.removed and git.removed > 0 and ("  " .. git.removed) or ""
	return ("%%#St_gitIcons#  %s%s%s%s"):format(escape(git.head or ""), added, changed, removed)
end

local function diagnostics_component()
	local buffer = statusline_buffer()
	local errors = #vim.diagnostic.get(buffer, { severity = vim.diagnostic.severity.ERROR })
	local warnings = #vim.diagnostic.get(buffer, { severity = vim.diagnostic.severity.WARN })
	local hints = #vim.diagnostic.get(buffer, { severity = vim.diagnostic.severity.HINT })
	local info = #vim.diagnostic.get(buffer, { severity = vim.diagnostic.severity.INFO })

	local result = " "
	result = result .. (errors > 0 and ("%#St_lspError# " .. errors .. " ") or "")
	result = result .. (warnings > 0 and ("%#St_lspWarning# " .. warnings .. " ") or "")
	result = result .. (hints > 0 and ("%#St_LspHints#󰛩 " .. hints .. " ") or "")
	result = result .. (info > 0 and ("%#St_LspInfo#󰋼 " .. info .. " ") or "")
	return result
end

local function lsp_component()
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = statusline_buffer() })) do
		return vim.o.columns > 100 and ("%#St_Lsp#   LSP ~ " .. escape(client.name) .. " ") or "%#St_Lsp#   LSP "
	end

	return ""
end

local function cwd_component()
	if vim.o.columns <= 85 then
		return ""
	end

	local cwd = vim.uv.cwd() or ""
	local name = cwd:match("([^/\\]+)[/\\]*$") or cwd
	return "%#St_cwd_sep#%#St_cwd_icon#󰉋 %#St_cwd_text# " .. escape(name) .. " "
end

function M.render()
	local progress = vim.o.columns < 120 and "" or lsp_message
	return table.concat({
		mode_component(),
		file_component(),
		git_component(),
		"%=",
		"%#St_LspMsg#" .. progress,
		"%=",
		diagnostics_component(),
		lsp_component(),
		cwd_component(),
		"%#St_pos_sep#%#St_pos_icon# %#St_pos_text# %l/%L ",
	})
end

local spinner = { "", "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥", "" }
vim.api.nvim_create_autocmd("LspProgress", {
	callback = function(event)
		local value = event.data and event.data.params and event.data.params.value
		if not value then
			return
		end

		local progress = ""
		if value.percentage then
			local index = math.max(1, math.min(10, math.floor(value.percentage / 10)))
			progress = spinner[index] .. " " .. value.percentage .. "%% "
		end

		local count = value.message and value.message:match("^(%d+/%d+)") or ""
		lsp_message = value.kind == "end" and "" or progress .. (value.title or "") .. " " .. count
		vim.cmd.redrawstatus()
	end,
})

setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.statusline = "%!v:lua.require('config.statusline').render()"

return M
