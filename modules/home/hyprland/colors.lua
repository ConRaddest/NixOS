hl.config({
  general = {
    col = {
      -- Match background to hide Hyprland xray border artifacts.
      active_border = "rgb(@background@)",
      inactive_border = "rgb(@background@)",
    },
  },
  group = {
    col = {
      border_active = "rgb(@primary@)",
      border_inactive = "rgb(@border@)",
      border_locked_active = "rgb(@info@)",
      border_locked_inactive = "rgb(@border@)",
    },
  },
})
