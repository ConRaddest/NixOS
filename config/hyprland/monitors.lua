local function assign_workspaces(monitor, workspaces)
	for _, ws in ipairs(workspaces) do
		hl.workspace_rule({ workspace = tostring(ws), monitor = monitor, default = true })
	end
end

-- monitor specific workspace rules
assign_workspaces("eDP-1", { 1, 2, 3 })
assign_workspaces("HDMI-A-1", { 4, 5, 6 })

-- monitor config
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60",
	position = "0x0",
	scale = 1,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "3440x1440@59.959",
	position = "1920x0",
	scale = 1,
})
