-- Startup
hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm app -- hyprpaper")
  hl.exec_cmd("uwsm app -s s -- lxqt-policykit-agent")
  hl.exec_cmd("uwsm app -- qs")
  hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")
  hl.exec_cmd("uwsm app -- hyprlock")
end)
