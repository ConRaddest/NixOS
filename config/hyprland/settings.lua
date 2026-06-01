-- Settings
hl.config({
  input = {
      accel_profile = "flat",
      sensitivity = 0.0,
  },
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 0,

    layout = "dwindle",
  },
  decoration = {
    rounding = 0,
    active_opacity = 0.93,
    inactive_opacity = 0.90,
    blur = {
      enabled = true,
      special = true,
      size = 6,
      passes = 2,
    },
  },
  animations = { enabled = true },
  dwindle = { preserve_split = false },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
})

-- Per-device settings targeting your trackpad specifically
hl.device({
    name = "msft0001:01-06cb:cd5f-touchpad",
    accel_profile = "adaptive",
    natural_scroll = true,
})