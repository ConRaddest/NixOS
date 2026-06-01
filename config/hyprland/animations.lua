-- Enable animations globally
hl.config({ 
    animations = { enabled = true } 
})

-- 1. Curve Definitions
-- Apple-style responsive spring (Critically damped, no sluggish inertia)
hl.curve("spring", {
    type = "spring",
    mass = 1,
    stiffness = 105,
    dampening = 17
})

-- Fast Bezier curve (Flat table structure syntax)
hl.curve("fast", {
    type = "bezier",
    points = { {0.05, 0.7}, {0.1, 1.0} }
})

-- 2. Animation Registry List
local animations = {
  { leaf = "windows",          speed = 2, spring = "spring" },
  { leaf = "windowsOut",       speed = 2, spring = "spring" },
  { leaf = "workspaces",       speed = 2, bezier = "fast" },
  { leaf = "specialWorkspace", speed = 2, bezier = "fast", style = "slidevert" },
  { leaf = "fade",             speed = 1, bezier = "fast" },
}

-- 3. Initialization Loop
for _, animation in ipairs(animations) do
  animation.enabled = true
  hl.animation(animation)
end

