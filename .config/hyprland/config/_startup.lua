-- Startup
hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm app -- hyprpaper")
  hl.exec_cmd("uwsm app -s s -- lxqt-policykit-agent")
  hl.exec_cmd("uwsm app -- qs")
  hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")
  -- hyprlock uses the wallpaper file directly, so this does not need a
  -- machine-dependent wait for hyprpaper to finish painting first.
  hl.exec_cmd("uwsm app -- hyprlock --immediate-render")
end)
