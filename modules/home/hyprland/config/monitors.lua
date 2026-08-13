local configured_monitors = require("nix.monitors")

local M = {}
local monitor_workspaces = {}
local workspace_aspect_ratio = {}
local workspace_scroll = {}

local function apply_workspace_aspect_ratio(workspace)
	local enabled = workspace_aspect_ratio[workspace.id]
	if enabled == nil then
		enabled = true
	end

	hl.config({
		layout = {
			single_window_aspect_ratio = enabled and { 16, 9 } or { 0, 0 },
		},
	})
end

local function assign_workspaces(monitor, workspaces)
	monitor_workspaces[monitor] = workspaces
	for _, workspace in ipairs(workspaces) do
		hl.workspace_rule({
			workspace = tostring(workspace),
			monitor = monitor,
			default = true,
			persistent = true,
		})
	end
end

function M.scroll_workspace(offset)
	local monitor = hl.get_active_monitor()
	if not monitor or not monitor.active_workspace then
		return
	end

	local workspaces = monitor_workspaces[monitor.name] or {}
	local state = workspace_scroll[monitor.name]
	local index = state and state.index

	if not index then
		for current_index, id in ipairs(workspaces) do
			if id == monitor.active_workspace.id then
				index = current_index
				break
			end
		end
	end

	local target_index = index and index + offset
	local target = target_index and workspaces[target_index]
	if not target then
		return
	end

	local generation = (state and state.generation or 0) + 1
	workspace_scroll[monitor.name] = { index = target_index, generation = generation }
	hl.dispatch(hl.dsp.focus({ workspace = target }))

	-- Continue fast wheel events from queued target, then resync with Hyprland.
	hl.timer(function()
		local current = workspace_scroll[monitor.name]
		if current and current.generation == generation then
			workspace_scroll[monitor.name] = nil
		end
	end, { timeout = 180, type = "oneshot" })
end

function M.toggle_workspace_aspect_ratio()
	local monitor = hl.get_active_monitor()
	local workspace = monitor and monitor.active_workspace
	if not workspace then
		return
	end

	workspace_aspect_ratio[workspace.id] = workspace_aspect_ratio[workspace.id] == false
	apply_workspace_aspect_ratio(workspace)
end

hl.on("workspace.active", apply_workspace_aspect_ratio)

for _, monitor in ipairs(configured_monitors) do
	assign_workspaces(monitor.output, monitor.workspaces)
	hl.monitor({
		output = monitor.output,
		mode = monitor.mode,
		position = monitor.position,
		scale = monitor.scale,
	})
end

return M
