hl.curve("spring", {
	type = "spring",
	mass = 1,
	stiffness = 105,
	dampening = 19,
})

hl.curve("fast", {
	type = "bezier",
	points = { { 0.05, 0.7 }, { 0.1, 1.0 } },
})

local animations = {
	{ enabled = false, leaf = "workspaces" },
	{ enabled = false, leaf = "windows", speed = 2, spring = "spring" },
	{ enabled = false, leaf = "windowsOut", speed = 2, spring = "spring" },
	{ enabled = false, leaf = "specialWorkspace", speed = 2, bezier = "fast", style = "slidevert" },
	{ enabled = false, leaf = "fade", speed = 1, bezier = "fast" },
}

for _, animation in ipairs(animations) do
	hl.animation(animation)
end
