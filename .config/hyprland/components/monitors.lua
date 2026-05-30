-- Monitor
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Disable the laptop panel while the lid is closed, and restore it when opened.
-- hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("hyprctl keyword monitor eDP-1,disable"), { locked = true })
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor eDP-1,preferred,auto,1"), { locked = true })

hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", default = true })

hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", default = true })
