---@meta

-- Hyprland Lua API type definitions
-- Auto-generated from hl-docs RST documentation

---@class HL.BindOptions
---@field repeating? boolean Enable repeat behavior.
---@field locked? boolean Allow the bind while locked.
---@field release? boolean Trigger on key release.
---@field non_consuming? boolean Do not consume the input event.
---@field auto_consuming? boolean Auto-consuming bind behavior.
---@field transparent? boolean Make the bind transparent.
---@field ignore_mods? boolean Ignore active modifiers.
---@field dont_inhibit? boolean Do not respect input inhibition.
---@field long_press? boolean Trigger as a long-press bind.
---@field submap_universal? boolean Apply across submaps.
---@field click? boolean Treat the bind as a click bind. Also implies ``release``.
---@field drag? boolean Treat the bind as a drag bind. Also implies ``release``.
---@field description? string Description shown for the bind.
---@field desc? string Short alias for ``description``. Used only if ``description`` is absent.
---@field device? {inclusive?: boolean, list?: string[]} Device filter table.

---@class HL.Box
---@field x number
---@field y number
---@field w number
---@field h number

---* ``animations.enabled``
---@alias HL.ConfigKey string

---@class HL.ConfigValueTypes

---Alias type.
---@alias HL.CssGap integer|{top?:integer, right?:integer, bottom?:integer, left?:integer}

---@class HL.DeviceSpec
---@field name string

---Runtime object.
---@class HL.Dispatcher

---* ``config.reloaded``
---@alias HL.EventName string

---:returns: any
---@class HL.EventSubscription

---@class HL.GestureSpec
---@field fingers integer Modifier string.
---@field direction string Modifier string.
---@field action string|function Modifier string.
---@field mods? string Modifier string.
---@field scale? number Gesture delta scale. Must be between ``0.1`` and ``10``.
---@field mode? string Action-specific mode string.
---@field zoom_level? string Action-specific zoom level string.
---@field workspace_name? string Workspace name for the ``special`` action.
---@field disable_inhibit? boolean Disable inhibition handling for this gesture.

---Alias type.
---@alias HL.Gradient string|{colors:string[], angle?:number}

---Size.
---@class HL.Group
---@field current? HL.Window|nil Current.
---@field current_index integer Current index.
---@field denied boolean Denied.
---@field locked boolean Locked.
---@field members? HL.Window|table|nil Members.
---@field size integer Size.

---Remove the keybind.
---@class HL.Keybind
---@field arg string Arg.
---@field auto_consuming boolean Auto consuming.
---@field catchall boolean Catchall.
---@field click boolean Click.
---@field description any Description.
---@field device_inclusive boolean Device inclusive.
---@field devices nil Devices.
---@field display_key string Display key.
---@field dont_inhibit boolean Dont inhibit.
---@field drag boolean Drag.
---@field enabled boolean Enabled.
---@field handler string Handler.
---@field has_description boolean Has description.
---@field ignore_mods boolean Ignore mods.
---@field key string Key.
---@field keycode integer Keycode.
---@field locked boolean Locked.
---@field long_press boolean Long press.
---@field modmask integer Modmask.
---@field mouse boolean Mouse.
---@field non_consuming boolean Non consuming.
---@field release boolean Release.
---@field repeating boolean Repeating.
---@field submap string Submap.
---@field submap_universal boolean Submap universal.
---@field transparent boolean Transparent. Methods ------- .. method:: HL.Keybind.is_enabled() Return whether the keybind is enabled. .. method:: HL.Keybind.set_enabled(enabled) Enable or disable the keybind. Parameters ---------- enabled : boolean New enabled state. .. method:: HL.Keybind.remove() .. method:: HL.Keybind.unbind() Remove the keybind.

---@class HL.LayerQueryFilter

---enabled : boolean
---@class HL.LayerRule

---no_anim = boolean?,
---@class HL.LayerRuleSpec
---@field name? string Rule name. Named rules are reused by later calls with the same name.
---@field enabled? boolean Whether the rule is enabled. Defaults to ``true``.
---@field match? table<string, string|boolean> Match table. Keys are rule match property names; values may be strings or booleans.
---@field no_anim? boolean Disable animation for matched layers.
---@field blur? boolean Enable blur for matched layers.
---@field blur_popups? boolean Enable popup blur for matched layers.
---@field ignore_alpha? number Alpha ignore threshold. Parsed as a float from ``0`` to ``1``.
---@field dim_around? boolean Dim around the layer.
---@field xray? boolean Enable xray behavior.
---@field animation? string Animation name.
---@field order? integer Layer rule ordering value.
---@field above_lock? integer Above-lock behavior. Parsed as an integer from ``0`` to ``2``.
---@field no_screen_share? boolean Prevent screen sharing.

---Y.
---@class HL.LayerSurface
---@field above_fullscreen? boolean|nil Above fullscreen.
---@field address string Address.
---@field h integer H.
---@field interactivity integer Interactivity.
---@field layer integer Layer.
---@field mapped boolean Mapped.
---@field monitor? HL.Monitor|nil Monitor.
---@field namespace string Namespace.
---@field pid integer Pid.
---@field w integer W.
---@field x integer X.
---@field y integer Y.

---ratio : number
---@class HL.LayoutContext
---@field area HL.Box Area.
---@field targets HL.LayoutTarget[] Targets. Methods ------- .. method:: HL.LayoutContext.grid_cell(i, cols, rows=None) Return a grid cell box from the layout area. .. method:: HL.LayoutContext.column(i, n) Return the ``i`` th column from ``n`` columns. .. method:: HL.LayoutContext.row(i, n) Return the ``i`` th row from ``n`` rows. .. method:: HL.LayoutContext.split(box, side, ratio) Split ``box`` and return the requested side. Parameters ---------- side : string Accepted values include ``left``, ``right``, ``top``, ``bottom``, ``up``, and ``down``. ratio : number Split ratio.

---:returns: boolean | string | nil
---@class HL.LayoutProvider

---box : :class:`HL.Box`
---@class HL.LayoutTarget
---@field index integer Index.
---@field window? HL.Window|nil Window.
---@field box HL.Box Box. Methods ------- .. method:: HL.LayoutTarget.place(box) .. method:: HL.LayoutTarget.set_box(box) Place this layout target into ``box``. Parameters ---------- box : :class:`HL.Box` Target geometry.

---if monitor then
---@class HL.Monitor
---@field active_special_workspace? HL.Workspace Active special workspace on this monitor, if any.
---@field active_workspace? HL.Workspace Active workspace on this monitor, if any.
---@field description string Human-readable monitor description.
---@field dpms_status boolean Whether DPMS is enabled for this monitor.
---@field focused? boolean Whether this monitor is focused.
---@field height integer Monitor height in pixels.
---@field id integer Numeric monitor ID.
---@field is_mirror boolean Whether this monitor is mirroring another output.
---@field mirrors HL.Monitor|table Monitor or monitors mirrored by this output.
---@field name string Monitor output name.
---@field position integer|table Monitor position.
---@field refresh_rate number Monitor refresh rate.
---@field scale number Monitor scale factor.
---@field size integer|table Monitor size.
---@field transform integer Monitor transform value.
---@field vrr_active boolean Whether variable refresh rate is currently active.
---@field width integer Monitor width in pixels.
---@field x integer X position.
---@field y integer Y position.

---if monitor then
---@alias HL.MonitorSelector string

---@class HL.MonitorSpec
---@field output string Disable the monitor.
---@field disabled? boolean Disable the monitor.
---@field mode? string Monitor mode, usually written as resolution and refresh rate.
---@field position? string Monitor position.
---@field scale? string|number Monitor scale factor.
---@field transform? integer|boolean Monitor transform value.
---@field mirror? string Output name of the monitor to mirror.
---@field bitdepth? integer|boolean Monitor bit depth option.
---@field vrr? integer|boolean Variable refresh rate option.
---@field reserved? integer|HL.CssGap Reserved space around the monitor.
---@field reserved_area? integer|HL.CssGap Reserved area field.
---@field cm? string Color-management mode.
---@field icc? string ICC profile path.
---@field supports_hdr? integer|boolean HDR capability override.
---@field supports_wide_color? integer|boolean Wide-color capability override.
---@field sdr_eotf? string SDR transfer function option.
---@field sdrbrightness? number|boolean SDR brightness option.
---@field sdrsaturation? number|boolean SDR saturation option.
---@field sdr_min_luminance? number|boolean SDR minimum luminance.
---@field sdr_max_luminance? integer|boolean SDR maximum luminance.
---@field min_luminance? number|boolean SDR minimum luminance.
---@field max_luminance? integer|boolean SDR maximum luminance.
---@field max_avg_luminance? integer|boolean Maximum average luminance.

---Get or set font size.
---@class HL.Notification

---@class HL.NotificationOptions

---@class HL.PermissionSpec
---@field binary string Alias for ``binary`` in table form.
---@field target string Alias for ``binary`` in table form.
---@field type string
---@field mode string

---timeout : integer
---@class HL.Timer

---@class HL.TimerOptions
---@field timeout integer
---@field type "repeat"|"oneshot"

---@class HL.Vec2
---@field x number
---@field y number

---Alias type.
---@alias HL.Vec2Like HL.Vec2|{x:number, y:number}|number[]|string

---Xwayland.
---@class HL.Window
---@field accepts_input boolean Accepts input.
---@field active? boolean|nil Active.
---@field address string Address.
---@field at integer|table At.
---@field class string Class.
---@field content_type string Content type.
---@field floating boolean Floating.
---@field focus_history_id integer Focus history id.
---@field fullscreen integer Fullscreen.
---@field fullscreen_client integer Fullscreen client.
---@field group? HL.Group|nil Group.
---@field hidden boolean Hidden.
---@field inhibiting_idle boolean Inhibiting idle.
---@field initial_class string Initial class.
---@field initial_title string Initial title.
---@field layout? HL.Window|boolean|integer|number|string|table|nil Layout.
---@field mapped boolean Mapped.
---@field monitor? HL.Monitor|nil Monitor.
---@field over_fullscreen boolean Over fullscreen.
---@field pid integer Pid.
---@field pinned boolean Pinned.
---@field size integer|table Size.
---@field stable_id integer Stable id.
---@field swallowing? HL.Window|nil Swallowing.
---@field tags string|table Tags.
---@field title string Title.
---@field visible boolean Visible.
---@field workspace? HL.Workspace|nil Workspace.
---@field xdg_description? string|nil Xdg description.
---@field xdg_tag? string|nil Xdg tag.
---@field xwayland boolean Xwayland.

---@class HL.WindowQueryFilter

---enabled : boolean
---@class HL.WindowRule

---@class HL.WindowRuleSpec
---@field name? string Rule name. Named rules are reused by later calls with the same name.
---@field enabled? boolean Whether the rule is enabled. Defaults to ``true``.
---@field match? table<string, string|number|boolean> Match table. Keys are rule match property names; values may be strings, numbers, or booleans.

---@alias HL.WindowSelector string|integer|HL.Window

---Return groups on this workspace.
---@class HL.Workspace
---@field active boolean Active.
---@field config_name string Config name.
---@field fullscreen_mode integer Fullscreen mode.
---@field fullscreen_window? HL.Window|nil Fullscreen window.
---@field groups? integer|nil Groups.
---@field has_fullscreen boolean Has fullscreen.
---@field has_urgent boolean Has urgent.
---@field id integer Id.
---@field is_empty boolean Is empty.
---@field is_persistent boolean Is persistent.
---@field last_window? HL.Window|nil Last window.
---@field monitor? HL.Monitor|nil Monitor.
---@field name string Name.
---@field special boolean Special.
---@field tiled_layout string Tiled layout.
---@field visible boolean Visible.
---@field windows integer Windows. Methods ------- .. method:: HL.Workspace.get_groups(...) Get groups. .. TODO: Document method parameters. :returns: any .. method:: HL.Workspace.get_windows(...) Get windows. .. TODO: Document method parameters. :returns: any

---@class HL.WorkspaceRuleSpec
---@field workspace string Whether the rule is enabled. Defaults to ``true``.
---@field enabled? boolean Whether the rule is enabled. Defaults to ``true``.
---@field monitor? string Monitor assigned to the workspace.
---@field default? boolean Mark as a default workspace rule.
---@field persistent? boolean Make the workspace persistent.
---@field gaps_in? integer|HL.CssGap
---@field gaps_out? integer|HL.CssGap
---@field float_gaps? integer|HL.CssGap Gap overrides.
---@field border_size? integer Border size override.
---@field no_border? boolean
---@field no_rounding? boolean
---@field decorate? boolean
---@field no_shadow? boolean Decoration-related workspace overrides.
---@field on_created_empty? string Command run when the workspace is created empty.
---@field default_name? string Default workspace name.
---@field layout? string Layout override.
---@field layout_opts? table<string, string|number|boolean> Layout options table. Keys must be strings; values may be strings, numbers, or booleans.
---@field animation? string Animation override. .. TODO: Confirm whether every listed field exists in the current source build; this page combines stub fields with source-derived parser behavior.

---@alias HL.WorkspaceSelector string|integer|HL.Workspace

---Namespace accessible as ``hl.dsp.cursor``.
---@class HL.DspCursorNamespace
local hl_dsp_cursor = {}

---@param spec {x: number, y: number}
---@return HL.Dispatcher
function hl_dsp_cursor.move(spec) end

---@param spec {corner: integer, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_cursor.move_to_corner(spec) end

---Namespace accessible as ``hl.dsp.group``.
---@class HL.DspGroupNamespace
local hl_dsp_group = {}

---@param spec {index: integer, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_group.active(spec) end

---@param spec? {window?: HL.WindowSelector} Toggle-action table.
---@return HL.Dispatcher
function hl_dsp_group.lock(spec) end

---@param spec? {window?: HL.WindowSelector} Toggle-action table.
---@return HL.Dispatcher
function hl_dsp_group.lock_active(spec) end

---@param spec? {forward?: boolean}
---@return HL.Dispatcher
function hl_dsp_group.move_window(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_group.next(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_group.prev(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_group.toggle(spec) end

---Namespace accessible as ``hl.dsp.window``.
---@class HL.DspWindowNamespace
local hl_dsp_window = {}

---@param spec {mode: string, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.alter_zorder(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.bring_to_top(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.center(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.clear_tags(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.close(spec) end

---@param spec? {next?: boolean, tiled?: boolean, floating?: boolean, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.cycle_next(spec) end

---@param spec? {window?: HL.WindowSelector} Toggle-action table.
---@return HL.Dispatcher
function hl_dsp_window.deny_from_group(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.drag(spec) end

---@param spec? {window?: HL.WindowSelector} Toggle-action table.
---@return HL.Dispatcher
function hl_dsp_window.float(spec) end

---@param spec? {mode?: string, action?: string, window?: HL.WindowSelector} Fullscreen options.
---@return HL.Dispatcher
function hl_dsp_window.fullscreen(spec) end

---@param spec {internal: integer, client: integer, action?: string, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.fullscreen_state(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.kill(spec) end

---@param spec {direction?: string, group_aware?: boolean, x?: number, y?: number, relative?: boolean, workspace?: HL.WorkspaceSelector, monitor?: HL.MonitorSelector, follow?: boolean, into_group?: string, into_or_create_group?: string, out_of_group?: string|boolean, window?: HL.WindowSelector} Window move operation table.
---@return HL.Dispatcher
function hl_dsp_window.move(spec) end

---@param spec? {window?: HL.WindowSelector} Toggle-action table.
---@return HL.Dispatcher
function hl_dsp_window.pin(spec) end

---@param spec? {window?: HL.WindowSelector} Toggle-action table.
---@return HL.Dispatcher
function hl_dsp_window.pseudo(spec) end

---@overload fun(table): HL.Dispatcher
---@return HL.Dispatcher
function hl_dsp_window.resize() end

---@param spec {prop: string, value: string, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.set_prop(spec) end

---@param spec {signal: integer, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.signal(spec) end

---@param spec {direction?: string, target?: HL.WindowSelector, with?: HL.WindowSelector, other?: HL.WindowSelector, next?: boolean, prev?: boolean, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.swap(spec) end

---@param spec {tag: string, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.tag(spec) end

---@param spec? {window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp_window.toggle_swallow(spec) end

---Namespace accessible as ``hl.dsp.workspace``.
---@class HL.DspWorkspaceNamespace
local hl_dsp_workspace = {}

---@param spec {monitor: HL.MonitorSelector, workspace?: HL.WorkspaceSelector}
---@return HL.Dispatcher
function hl_dsp_workspace.move(spec) end

---@param spec {workspace: HL.WorkspaceSelector, name?: string}
---@return HL.Dispatcher
function hl_dsp_workspace.rename(spec) end

---@param spec {monitor1: HL.MonitorSelector, monitor2: HL.MonitorSelector}
---@return HL.Dispatcher
function hl_dsp_workspace.swap_monitors(spec) end

---@param name? string Special workspace name. Omit for the default special workspace.
---@return HL.Dispatcher
function hl_dsp_workspace.toggle_special(name) end

---Namespace accessible as ``hl.dsp``.
---@class HL.DspNamespace
local hl_dsp = {}

---@param spec? {monitor?: HL.MonitorSelector} Toggle-action table. May include ``monitor``.
---@return HL.Dispatcher
function hl_dsp.dpms(spec) end

---@param name string Event string.
---@return HL.Dispatcher
function hl_dsp.event(name) end

---@param cmd string Command to execute. Must not be empty.
---@param rules? table Window rules to apply to the spawned process.
---@return HL.Dispatcher
function hl_dsp.exec_cmd(cmd, rules) end

---@param cmd string Raw command string to spawn.
---@return HL.Dispatcher
function hl_dsp.exec_raw(cmd) end

---@return HL.Dispatcher
function hl_dsp.exit() end

---@param spec {direction?: string, monitor?: HL.MonitorSelector, workspace?: HL.WorkspaceSelector, on_current_monitor?: boolean, window?: HL.WindowSelector, urgent_or_last?: boolean, last?: boolean} Focus operation table. Must contain one recognized focus field.
---@return HL.Dispatcher
function hl_dsp.focus(spec) end

---@param timeout number Idle timeout value passed to Hyprland.
---@return HL.Dispatcher
function hl_dsp.force_idle(timeout) end

---@return HL.Dispatcher
function hl_dsp.force_renderer_reload() end

---@param name string Global shortcut string.
---@return HL.Dispatcher
function hl_dsp.global(name) end

---@param message string Layout message string.
---@return HL.Dispatcher
function hl_dsp.layout(message) end

---@return HL.Dispatcher
function hl_dsp.no_op() end

---@param spec {window: HL.WindowSelector} Must contain ``window``.
---@return HL.Dispatcher
function hl_dsp.pass(spec) end

---@param spec {mods: string, key: string, state: string, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp.send_key_state(spec) end

---@param spec {mods: string, key: string, window?: HL.WindowSelector}
---@return HL.Dispatcher
function hl_dsp.send_shortcut(spec) end

---@param name string Submap name to activate.
---@return HL.Dispatcher
function hl_dsp.submap(name) end

---Namespace accessible as ``hl.layout``.
---@class HL.LayoutNamespace
local hl_layout = {}

---@param name string Name.
---@param provider HL.LayoutProvider Provider.
function hl_layout.register(name, provider) end

---Namespace accessible as ``hl.notification``.
---@class HL.NotificationNamespace
local hl_notification = {}

---@param opts? HL.NotificationOptions Opts.
---@return HL.Notification
function hl_notification.create(opts) end

---@return HL.Notification[]
function hl_notification.get() end

---Namespace accessible as ``hl.plugin``.
---@class HL.PluginNamespace
local hl_plugin = {}

---@param ... any
---@return any
function hl_plugin.load(...) end

---@class HL.API
---@field dsp HL.DspNamespace
---@field notification HL.NotificationNamespace
---@field layout HL.LayoutNamespace
---@field plugin HL.PluginNamespace
hl = {}

---@param spec {leaf: string, enabled: boolean, speed: number, bezier?: string, spring?: string, style?: string} Animation configuration table.
function hl.animation(spec) end

---@param keys string Key combination string. Modifiers come first and are separated with ``+``. The final non-modifier entries are interpreted as keysyms, keycodes, or special symbols.
---@param dispatcher HL.Dispatcher|function Dispatcher returned by ``hl.dsp.*`` or a Lua callback function.
---@param opts? HL.BindOptions Additional keybind flags.
---@return HL.Keybind
function hl.bind(keys, dispatcher, opts) end

---@param config table Nested configuration table. Leaf fields must correspond to valid :class:`HL.ConfigKey` entries.
function hl.config(config) end

---@param name string Name used later by :func:`hl.animation`.
---@param spec table Curve definition table. The ``type`` field determines which shape is used.
function hl.curve(name, spec) end

---@overload fun(string, string, function)
---@param name string Submap name.
---@param fn function Function called while the submap is active during config evaluation. Binds created inside this callback are assigned to the submap.
function hl.define_submap(name, fn) end

---@param spec HL.DeviceSpec Device configuration table. ``name`` is required.
function hl.device(spec) end

---@param dispatcher HL.Dispatcher|function Dispatcher.
---@return any
function hl.dispatch(dispatcher) end

---@param name string Environment variable name. Must not be empty.
---@param value string Environment variable value.
---@param dbus? boolean If true, also run ``dbus-update-activation-environment --systemd`` for this variable.
function hl.env(name, value, dbus) end

---@param cmd string Cmd.
---@param rules? table<string, string|number|boolean> Rules.
function hl.exec_cmd(cmd, rules) end

---@param spec HL.GestureSpec Gesture definition table.
function hl.gesture(spec) end

---@return HL.Monitor|nil
function hl.get_active_monitor() end

---@param monitor? HL.MonitorSelector Monitor.
---@return HL.Workspace|nil
function hl.get_active_special_workspace(monitor) end

---@return HL.Window|nil
function hl.get_active_window() end

---@param monitor? HL.MonitorSelector Monitor.
---@return HL.Workspace|nil
function hl.get_active_workspace(monitor) end

---@param key HL.ConfigKey|string Key.
---@return any, string
function hl.get_config(key) end

---@return string
function hl.get_current_submap() end

---@return HL.Vec2|nil
function hl.get_cursor_pos() end

---@return HL.Window|nil
function hl.get_last_window() end

---@param monitor? HL.MonitorSelector Monitor.
---@return HL.Workspace|nil
function hl.get_last_workspace(monitor) end

---@param filters? HL.LayerQueryFilter Filters.
---@return HL.LayerSurface[]
function hl.get_layers(filters) end

---local monitor = hl.get_monitor(0)
---@param selector HL.MonitorSelector Monitor selector. May be a monitor output name, numeric monitor ID, or existing :class:`HL.Monitor` object.
---@return HL.Monitor|nil
function hl.get_monitor(selector) end

---@param x number|HL.Vec2 X.
---@param y? number Y.
---@return HL.Monitor|nil
function hl.get_monitor_at(x, y) end

---@return HL.Monitor|nil
function hl.get_monitor_at_cursor() end

---@return HL.Monitor[]
function hl.get_monitors() end

---@return HL.Window|nil
function hl.get_urgent_window() end

---@param selector HL.WindowSelector Selector.
---@return HL.Window|nil
function hl.get_window(selector) end

---@param filters? HL.WindowQueryFilter Filters.
---@return HL.Window[]
function hl.get_windows(filters) end

---@param selector HL.WorkspaceSelector Selector.
---@return HL.Workspace|nil
function hl.get_workspace(selector) end

---@param workspace HL.WorkspaceSelector Workspace.
---@return HL.Window[]
function hl.get_workspace_windows(workspace) end

---@return HL.Workspace[]
function hl.get_workspaces() end

---@param spec HL.LayerRuleSpec Rule table.
---@return HL.LayerRule
function hl.layer_rule(spec) end

---@param spec HL.MonitorSpec Monitor configuration table. The ``output`` field is required.
function hl.monitor(spec) end

---@param event HL.EventName Event.
---@param cb fun(...) Cb.
---@return HL.EventSubscription
function hl.on(event, cb) end

---@overload fun(spec: HL.PermissionSpec)
---@overload fun(binary: string, type: string, mode: string)
function hl.permission(...) end

---@param callback function Callback.
---@param opts HL.TimerOptions Opts.
---@return HL.Timer
function hl.timer(callback, opts) end

---@param ... any
---@return any
function hl.unbind(...) end

---@param ... any
---@return any
function hl.version(...) end

---@param spec HL.WindowRuleSpec Rule table.
---@return HL.WindowRule
function hl.window_rule(spec) end

---@param spec HL.WorkspaceRuleSpec Rule table.
function hl.workspace_rule(spec) end

-- Wire up namespaces
hl.dsp = hl_dsp
hl.layout = hl_layout
hl.notification = hl_notification
hl.plugin = hl_plugin
hl_dsp.cursor = hl_dsp_cursor
hl_dsp.group = hl_dsp_group
hl_dsp.window = hl_dsp_window
hl_dsp.workspace = hl_dsp_workspace
