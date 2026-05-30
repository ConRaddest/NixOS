-- Settings
hl.config({
  input = {
    kb_layout = "za",
    follow_mouse = 1,
    touchpad = { natural_scroll = true },
  },
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 0,

    layout = "dwindle",
  },
  decoration = {
    rounding = 0,
    active_opacity = 0.98,
    inactive_opacity = 0.95,
    blur = {
      enabled = true,
      special = true,
      size = 6,
      passes = 2,
    },
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
})
