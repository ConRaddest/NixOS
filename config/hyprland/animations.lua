-- Animations
hl.curve("fast", {
  type = "bezier",
  points = { { 0.05, 0.7 }, { 0.1, 1.0 } },
})

local animations = {
  { leaf = "windows",          speed = 4, bezier = "fast" },
  { leaf = "windowsOut",       speed = 4, bezier = "fast" },
  { leaf = "border",           speed = 8, bezier = "fast" },
  { leaf = "fade",             speed = 4, bezier = "fast" },
  { leaf = "workspaces",       speed = 4, bezier = "fast" },
  { leaf = "specialWorkspace", speed = 4, bezier = "fast", style = "slidevert" },
}

for _, animation in ipairs(animations) do
  animation.enabled = true
  hl.animation(animation)
end
