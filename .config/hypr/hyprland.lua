-- Hyprland config (Lua). The .conf format is removed in 0.57.
-- API ref: https://wiki.hypr.land/Configuring/

----------------------------------------------------------------------
-- PLUGINS
----------------------------------------------------------------------

hl.plugin.load("/usr/lib/libhy3.so")
hl.plugin.load("/usr/lib/libhyprfocus.so")

----------------------------------------------------------------------
-- MONITORS
----------------------------------------------------------------------

-- primary display: workspaces default here, laptop panel is the fallback
local primaryMonitor = "desc:Samsung Electric Company LS49AG95 HNTW800039"

-- fallback for anything not matched below
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
-- monitor configuration
-- layout: QHX left of primary, laptop panel below it. auto-* placement lets
-- Hyprland compute the offsets from the real (rotated, scaled) sizes, so the
-- edges actually touch - directional monitor moves only work when they do.
hl.monitor({ output = primaryMonitor, mode = "3840x1080@120", position = "0x0", scale = "1" })
hl.monitor({ output = "desc:QHX GF340H", mode = "highres", position = "auto-left", scale = "1", transform = 3 })
hl.monitor({ output = "desc:BOE YHB0AP23", mode = "1600x2560@120", position = "auto-down", scale = "2", transform = 1 })

----------------------------------------------------------------------
-- PROGRAMS
----------------------------------------------------------------------

local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "rofi -show drun -theme dmenu"
local locker      = "hyprlock"
local mainMod     = "SUPER"

local cursorTheme = "gnome"
local cursorSize  = "24"
local gtkTheme    = "Qogir-Dark"
local iconTheme   = "Papirus"
local font        = "TerminessNerdFont 12"

----------------------------------------------------------------------
-- ENVIRONMENT
----------------------------------------------------------------------

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GTK_THEME", gtkTheme)
hl.env("QT_STYLE_OVERRIDE", "gtk")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("HYPRCURSOR_THEME", cursorTheme)
hl.env("HYPRCURSOR_SIZE", cursorSize)
hl.env("XCURSOR_THEME", cursorTheme)
hl.env("XCURSOR_SIZE", cursorSize)
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
hl.env("TERMINAL", terminal)
-- force eGPU as primary GPU if available
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0")

----------------------------------------------------------------------
-- AUTOSTART
----------------------------------------------------------------------

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("cliphist")
  hl.exec_cmd("wl-paste --watch cliphist store")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("hyprland-deactivate-touchscreen")
  hl.exec_cmd("gammastep-indicator -l 52:13")

  -- screenshare / systemd session environment
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  -- xdg-desktop-portal.service has Requisite=graphical-session.target; launching
  -- Hyprland straight from a TTY never starts it, so screensharing silently dies.
  hl.exec_cmd("systemctl --user start hyprland-session.target")

  hl.exec_cmd("hyprctl setcursor " .. cursorTheme .. " " .. cursorSize)

  -- gtk theming. gtk reads antialiasing/hinting from gsettings, not fontconfig.
  local schema = "org.gnome.desktop.interface"
  for _, kv in ipairs({
    { "gtk-theme",           gtkTheme },
    { "icon-theme",          iconTheme },
    { "cursor-theme",        cursorTheme },
    { "cursor-size",         cursorSize },
    { "font-name",           font },
    { "monospace-font-name", font },
    { "document-font-name",  font },
    { "color-scheme",        "prefer-dark" },
    { "font-antialiasing",   "rgba" },
    { "font-hinting",        "slight" },
  }) do
    hl.exec_cmd(("gsettings set %s %s '%s'"):format(schema, kv[1], kv[2]))
  end
end)

hl.on("hyprland.shutdown", function()
  hl.exec_cmd("systemctl --user stop hyprland-session.target")
end)

----------------------------------------------------------------------
-- LOOK AND FEEL
----------------------------------------------------------------------

hl.config({
  general = {
    gaps_in          = 0,
    gaps_out         = 0,
    border_size      = 0,
    col              = {
      active_border   = "rgba(242933ff)",
      inactive_border = "rgba(242933ff)",
    },
    layout           = "hy3",
    allow_tearing    = true,
    resize_on_border = false,
  },

  decoration = {
    rounding = 0,
    blur     = { enabled = false, size = 3, passes = 1 },
    shadow   = { enabled = false },
  },

  animations = { enabled = true },

  xwayland = {
    force_zero_scaling   = true,
    use_nearest_neighbor = true,
  },

  dwindle = {
    preserve_split        = true,
    smart_resizing        = false,
    use_active_for_splits = true,
    force_split           = 2, -- always split to the right
  },

  master = { new_status = "master" },

  plugin = {
    -- flashfocus-like focus feedback. flash, not shrink/slide: border_size and
    -- rounding are 0, so a geometry wobble reads as noise.
    -- flash on every pointer cross.
    hyprfocus = {
      enable                   = true,
      animate_floating         = true,
      only_on_monitor_change   = false,
      keyboard_focus_animation = "flash",
      fade_opacity             = 0.8,
    },

    -- hy3. autotile reproduces sway's "split along the longer axis" behaviour,
    -- so manual make_group is only needed to override it.
    hy3 = {
      tab_first_window = true,
      autotile = {
        enable           = true,
        ephemeral_groups = true,
        trigger_width    = 0,
        trigger_height   = 0,
      },
      tabs = {
        height    = 22,
        padding   = 4,
        from_top  = true,
        radius    = 0,
        text_font = "TerminessNerdFontMono",
        colors    = {
          active          = "rgba(2e3440ff)",
          active_border   = "rgba(88c0d0ff)",
          active_text     = "rgba(d8dee9ff)",
          focused         = "rgba(2e3440ff)",
          focused_border  = "rgba(4c566aff)",
          focused_text    = "rgba(d8dee9ff)",
          inactive        = "rgba(242933ff)",
          inactive_border = "rgba(242933ff)",
          inactive_text   = "rgba(4c566aff)",
          urgent          = "rgba(bf616aff)",
          urgent_border   = "rgba(bf616aff)",
          urgent_text     = "rgba(eceff4ff)",
        },
      },
    },
  },

  ecosystem = {
    no_donation_nag = true,
    no_update_news  = true,
  },

  misc = {
    -- false: xdg-activation requests (telegram et al on a new message) only mark
    -- the window urgent instead of yanking focus/workspace
    focus_on_activate        = false,
    animate_manual_resizes   = true,
    force_default_wallpaper  = 0,
    disable_hyprland_logo    = true,
    disable_splash_rendering = true,
    splash_font_family       = "Terminus",
    background_color         = 0xff242933,
    middle_click_paste       = false,
  },

  debug = { vfr = true },

  input = {
    kb_layout      = "us",
    kb_variant     = "altgr-intl",
    kb_options     = "caps:escape",
    follow_mouse   = 1,
    force_no_accel = false,
    accel_profile  = "flat",
    sensitivity    = 0, -- -1.0 to 1.0, 0 means no modification
    touchpad       = { natural_scroll = true },
  },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "default" })
-- speed is in 100ms units, so lower = snappier
hl.animation({ leaf = "hyprfocusIn", enabled = true, speed = 0.8, bezier = "default" })
hl.animation({ leaf = "hyprfocusOut", enabled = true, speed = 0.8, bezier = "default" })

----------------------------------------------------------------------
-- KEYBINDS (sway-like, via hy3)
----------------------------------------------------------------------

local hy3 = hl.plugin.hy3

hl.bind(mainMod .. " + SHIFT + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hy3.kill_active())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + d", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grimshot save active ~/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"))

-- sway "split h/v": the next window opens beside/below instead of following
-- dwindle's automatic split. toggle = pressing again undoes the pending split.
hl.bind(mainMod .. " + SHIFT + b", hy3.make_group("h", { toggle = true }))
hl.bind(mainMod .. " + SHIFT + v", hy3.make_group("v", { toggle = true }))
hl.bind(mainMod .. " + w", hy3.make_group("tab", { toggle = true }))

-- sway "layout toggle split" / tabbed
hl.bind(mainMod .. " + e", hy3.change_group("opposite"))
hl.bind(mainMod .. " + s", hy3.change_group("toggletab"))

-- sway "focus parent" / "focus child"
hl.bind(mainMod .. " + a", hy3.change_focus("raise"))
hl.bind(mainMod .. " + SHIFT + a", hy3.change_focus("lower"))

hl.bind(mainMod .. " + f", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + p", hy3.expand("expand"))
hl.bind(mainMod .. " + o", hy3.equalize())

-- focus / move. hy3's variants are group-aware; the built-ins are not.
local dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(dirs) do
  hl.bind(mainMod .. " + " .. key, hy3.move_focus(dir))
  -- hy3:movewindow stops at the workspace edge. ponytail: no edge detection,
  -- just move and see if the window budged; if not, hand it to the neighbouring
  -- monitor (a no-op warning when there is none).
  hl.bind(mainMod .. " + SHIFT + " .. key, function()
    local w = hl.get_active_window()
    if not w then return end
    local before = w.at
    hl.dispatch(hy3.move_window(dir))
    local after = w.at
    if before.x == after.x and before.y == after.y then
      hl.dispatch(hl.dsp.window.move({ monitor = dir:sub(1, 1) }))
    end
  end)
end

-- tab cycling within a hy3 tab group
hl.bind(mainMod .. " + tab", hy3.focus_tab({ direction = "right", wrap = true }))
hl.bind(mainMod .. " + SHIFT + tab", hy3.focus_tab({ direction = "left", wrap = true }))

-- workspaces
-- all workspaces live on the primary display. If it's not connected Hyprland
-- falls back to the focused monitor (the laptop panel) on its own.
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.workspace_rule({ workspace = tostring(i), monitor = primaryMonitor, default = (i == 1) })
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hy3.move_to_workspace(tostring(i)))
end

-- laptop lid. `hyprctl keyword` is gone in 0.57; hl.monitor() works at runtime and
-- merges into the existing rule, so re-enabling keeps mode/position/scale/transform.
local laptopPanel = "desc:BOE YHB0AP23"

local function setLaptopPanel(disabled)
  -- hl.get_monitors() lists only enabled, non-mirror monitors: undocked it's just
  -- the panel, and blanking the last screen leaves nowhere to put the windows.
  if disabled and #hl.get_monitors() < 2 then return end
  hl.monitor({ output = laptopPanel, disabled = disabled })
end

hl.bind("switch:off:Lid Switch", function() setLaptopPanel(false) end, { locked = true })
hl.bind("switch:on:Lid Switch", function() setLaptopPanel(true) end, { locked = true })

-- touchscreen
hl.bind(mainMod .. " + SHIFT + t", hl.dsp.exec_cmd("hyprland-activate-touchscreen"))
hl.bind(mainMod .. " + t", hl.dsp.exec_cmd("hyprland-deactivate-touchscreen"))

-- resize submap, sway semantics: h/j/k/l shrink the named edge, CTRL grows it.
--
-- hy3 only ever resizes the right/bottom edge from a keybind (its resizeTarget
-- gets CORNER_NONE and picks Right/Down), so left/top edges are done by hopping
-- focus to the neighbour and moving *its* right/bottom edge instead.
local OPPOSITE = { left = "right", up = "down" }

-- `amount` is outward growth of `edge`: positive grows the window, negative shrinks it.
local function resize_edge(edge, amount)
  return function()
    if edge == "right" then
      hl.dispatch(hl.dsp.window.resize({ x = amount, y = 0, relative = true }))
      return
    elseif edge == "down" then
      hl.dispatch(hl.dsp.window.resize({ x = 0, y = amount, relative = true }))
      return
    end

    local before = hl.get_active_window()
    hl.dispatch(hy3.move_focus(edge, { warp = false }))
    local after = hl.get_active_window()

    -- no neighbour that way: focus didn't move, so resizing would hit ourselves
    if not before or not after or before.address == after.address then return end

    -- our left/top edge is the neighbour's right/bottom edge, hence the sign flip
    if edge == "left" then
      hl.dispatch(hl.dsp.window.resize({ x = -amount, y = 0, relative = true }))
    else
      hl.dispatch(hl.dsp.window.resize({ x = 0, y = -amount, relative = true }))
    end

    hl.dispatch(hy3.move_focus(OPPOSITE[edge], { warp = false }))
  end
end

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
  local edges = { h = "left", j = "down", k = "up", l = "right" }
  for key, edge in pairs(edges) do
    hl.bind(key, resize_edge(edge, -100))              -- shrink that edge inward
    hl.bind("SHIFT + " .. key, resize_edge(edge, 100)) -- extend that edge outward
    hl.bind("CTRL + " .. key, resize_edge(edge, -30))
    hl.bind("CTRL + SHIFT + " .. key, resize_edge(edge, 30))
  end
  hl.bind("escape", hl.dsp.submap("reset"))
  hl.bind("return", hl.dsp.submap("reset"))
end)

-- system mode submap
hl.bind(mainMod .. " + SHIFT + escape", hl.dsp.submap("system_mode"))
hl.define_submap("system_mode", function()
  -- ponytail: lua lambda dispatches both in-process; no hyprctl subshell,
  -- so a blocking command can't keep us stuck in the submap
  local function leave_and_run(cmd)
    return function()
      hl.dispatch(hl.dsp.submap("reset"))
      hl.dispatch(hl.dsp.exec_cmd(cmd))
    end
  end
  hl.bind("l", leave_and_run(locker))
  hl.bind("e", function()
    hl.dispatch(hl.dsp.submap("reset"))
    hl.dispatch(hl.dsp.exit())
  end)
  hl.bind("s", leave_and_run("systemctl suspend"))
  hl.bind("r", leave_and_run("systemctl reboot"))
  hl.bind("SHIFT + s", leave_and_run("systemctl poweroff"))
  hl.bind("escape", hl.dsp.submap("reset"))
  hl.bind("return", hl.dsp.submap("reset"))
end)

-- volume / brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind(mainMod .. " + SHIFT + p", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind(mainMod .. " + SHIFT + n", hl.dsp.exec_cmd("playerctl next"))
