---@module 'hl'

require("layouts/columns")
require("layouts/monocle")

local HOME = os.getenv("HOME")

-- ─── Monitors ────────────────────────────────────────────────────────────────
-- Layout (all connected):
--   HDMI-A-1   3840x2160  auto (above row when present)
--   DP-2       1440x900   pos 0x0    rotate 90° (vertical), effective width 900px
--   DP-1       2560x1440  pos 900x0  primary
--   DP-3       1440x900   pos 3460x0
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60",  position = "auto",   scale = 1 })
hl.monitor({ output = "DP-1",     mode = "2560x1440@164", position = "900x0",  scale = 1 })
hl.monitor({ output = "DP-2",     mode = "1440x900@74",   position = "0x0",    scale = 1, transform = 1 })
hl.monitor({ output = "DP-3",     mode = "1440x900@60",   position = "3460x0", scale = 1 })
hl.monitor({ output = "",         mode = "preferred",      position = "auto",   scale = 1 })

-- ─── Autostart ───────────────────────────────────────────────────────────────
hl.on("hyprland.start", function()
    hl.exec_cmd(HOME .. "/.config/hypr/scripts/hooks/window-opened.sh")
    hl.exec_cmd("mpvpaper -o 'no-audio hwdec=auto loop-file=inf keepaspect=no demuxer-max-bytes=128M demuxer-max-back-bytes=20M cache=no input-ipc-server=/tmp/mpv-socket script=" .. HOME .. "/.config/mpv/scripts/wallpaper-timer.lua' '*' " .. HOME .. "/documents/wallpapers/animated/playlist.m3u")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(HOME .. "/.customscripts/alert-daemon.sh")
    hl.exec_cmd("ags run " .. HOME .. "/.config/dotfiles/ags-2.0/app.ts")
    hl.exec_cmd(HOME .. "/.config/wacom/init.sh")
    hl.exec_cmd("hypridle")
end)

-- ─── Environment ─────────────────────────────────────────────────────────────
hl.env("XCURSOR_SIZE", "16")

-- ─── Look and Feel ───────────────────────────────────────────────────────────
hl.config({
    general = {
        gaps_in  = 7,
        gaps_out = 20,
        border_size = 0,
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(00000000)",
        },
        layout            = "lua:columns",
        no_focus_fallback = true,
        resize_on_border  = true,
    },

    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size    = 3,
            passes  = 1,
            xray    = false,
        },
        active_opacity     = 0.97,
        inactive_opacity   = 0.90,
        fullscreen_opacity = 1,
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo = true,
    },

    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- ─── Animations ──────────────────────────────────────────────────────────────
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })

-- ─── Device ──────────────────────────────────────────────────────────────────
hl.device({ name = "epic-mouse-v1" })

-- ─── Window Rules ────────────────────────────────────────────────────────────
hl.window_rule({
    name    = "opaque-apps",
    match   = { class = "^(rofi|discord|firefox)$" },
    opacity = "1.0 1.0",
})

hl.window_rule({
    name             = "xwaylandvideobridge",
    match            = { class = "^(xwaylandvideobridge)$" },
    opacity          = "0.0 0.0",
    no_anim          = true,
    no_focus         = true,
    no_initial_focus = true,
})

hl.window_rule({
    name    = "flameshot-no-anim",
    match   = { class = "^(flameshot)$" },
    no_anim = true,
})

-- ─── Keybindings ─────────────────────────────────────────────────────────────
local mainMod = "SUPER"

-- Apps
hl.bind(mainMod .. " + Return",         hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + W",              hl.dsp.window.close())
hl.bind(mainMod .. " + Q",              hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + CTRL + Q",       hl.dsp.exit())
hl.bind(mainMod .. " + M",              hl.dsp.exec_cmd("env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 rofi -show-icons -icon-theme Papirus -show drun"))
hl.bind(mainMod .. " + D",              hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + B",              hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + S",              hl.dsp.exec_cmd("echo 'cycle pause' | socat - /tmp/mpv-socket"))
hl.bind(mainMod .. " + N",              hl.dsp.exec_cmd(HOME .. "/.customscripts/next-wallpaper"))
hl.bind(mainMod .. " + SHIFT + B",      hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mainMod .. " + SHIFT + S",      hl.dsp.exec_cmd(HOME .. "/.customscripts/screenshot"))
hl.bind(mainMod .. " + SHIFT + R",      hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/functions/record.sh"))
hl.bind(mainMod .. " + CTRL + R",         hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + C",      hl.dsp.exec_cmd("hyprpicker -a --format=hex"))
hl.bind(mainMod .. " + F",              hl.dsp.exec_cmd(HOME .. "/.customscripts/stop-alert-daemon.sh"))

-- Layout toggle
hl.bind(mainMod .. " + Tab",            hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + Tab",    hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- AGS
hl.bind(mainMod .. " + Backspace",      hl.dsp.exec_cmd("ags quit && ags run " .. HOME .. "/.config/dotfiles/ags-2.0/app.ts"))
hl.bind(mainMod .. " + SHIFT + Backspace", hl.dsp.exec_cmd("ags quit"))
hl.bind(mainMod .. " + G",              hl.dsp.exec_cmd("ags run " .. HOME .. "/.config/dotfiles/ags-2.0/app.ts"))
hl.bind(mainMod .. " + SHIFT + G",      hl.dsp.exec_cmd("ags quit"))

-- ─── Columns Layout ──────────────────────────────────────────────────────────
-- NOTE: SUPER+Q is kept as hyprlock (original hyprland bind). 'next' has no bind.

-- Focus (layout-aware: monocle uses prev/next, others use directional)
hl.bind(mainMod .. " + J",              hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/functions/nav.sh left"))
hl.bind(mainMod .. " + L",              hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/functions/nav.sh right"))
hl.bind(mainMod .. " + I",              hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/functions/nav.sh up"))
hl.bind(mainMod .. " + K",              hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/functions/nav.sh down"))

-- Shuffle (move windows)
hl.bind(mainMod .. " + SHIFT + J",      hl.dsp.layout("shuffle_left"))
hl.bind(mainMod .. " + SHIFT + L",      hl.dsp.layout("shuffle_right"))
hl.bind(mainMod .. " + SHIFT + I",      hl.dsp.layout("shuffle_up"))
hl.bind(mainMod .. " + SHIFT + K",      hl.dsp.layout("shuffle_down"))

-- Grow (resize)
hl.bind(mainMod .. " + CTRL + J",       hl.dsp.layout("grow_left"))
hl.bind(mainMod .. " + CTRL + L",       hl.dsp.layout("grow_right"))
hl.bind(mainMod .. " + CTRL + I",       hl.dsp.layout("grow_up"))
hl.bind(mainMod .. " + CTRL + K",       hl.dsp.layout("grow_down"))

-- Column operations
hl.bind(mainMod .. " + CTRL + SHIFT + J", hl.dsp.layout("swap_column_left"))
hl.bind(mainMod .. " + CTRL + SHIFT + L", hl.dsp.layout("swap_column_right"))
hl.bind(mainMod .. " + Space",            hl.dsp.layout("toggle_split"))
hl.bind(mainMod .. " + R",               hl.dsp.layout("normalize"))

-- ─── Tmp Workspace Helpers ───────────────────────────────────────────────────
-- Encoding: workspace N is main; sub-workspaces are N*10+1, N*10+2, ... N*10+9
-- e.g. workspace 2 → subs 21, 22, ..., 29 (auto-deleted by Hyprland when empty)

local function get_base_ws(ws_id)
    if ws_id < 10 then return ws_id end
    return math.floor(ws_id / 10)
end

local function get_sub_level(ws_id)
    if ws_id < 10 then return 0 end
    return ws_id % 10
end

local function next_subws(ws_id)
    local base = get_base_ws(ws_id)
    local sub  = get_sub_level(ws_id)
    if sub >= 9 then return base end
    return base * 10 + sub + 1
end

local function prev_subws(ws_id)
    local base = get_base_ws(ws_id)
    local sub  = get_sub_level(ws_id)
    if sub <= 1 then return base end
    return base * 10 + sub - 1
end

local function ws_exists(ws_id)
    return hl.get_workspace(ws_id) ~= nil
end

-- Switch to workspace i or cycle through its sub-workspaces when already there.
local function switch_to_ws(i)
    local active    = hl.get_active_workspace()
    local active_id = active and active.id or 0

    if get_base_ws(active_id) == i then
        -- Cycle to the next existing sub-workspace, skipping gaps.
        local next_id = next_subws(active_id)
        while next_id ~= i and not ws_exists(next_id) do
            next_id = next_subws(next_id)
        end
        hl.dispatch(hl.dsp.focus({ workspace = next_id, on_current_monitor = true }))
    else
        -- Different base: follow if visible on another monitor, else bring here.
        local on_current = true
        for _, mon in ipairs(hl.get_monitors()) do
            if mon.active_workspace and mon.active_workspace.id == i then
                on_current = false
                break
            end
        end
        hl.dispatch(hl.dsp.focus({ workspace = i, on_current_monitor = on_current }))
    end
end

-- Move the active window to workspace i, using sub-workspace logic when i == own base.
local function move_to_ws(i)
    local active    = hl.get_active_workspace()
    local active_id = active and active.id or 0
    local windows   = active and active.windows or 0

    if get_base_ws(active_id) == i then
        local is_main = get_sub_level(active_id) == 0
        local goto_id = (is_main or windows > 1) and next_subws(active_id) or prev_subws(active_id)
        hl.dispatch(hl.dsp.window.move({ workspace = goto_id, follow = false }))
    else
        hl.dispatch(hl.dsp.window.move({ workspace = i, follow = false }))
    end
end

-- ─── Workspaces ──────────────────────────────────────────────────────────────
local wsKeys = { "grave", "1", "2", "8", "9", "0", "minus", "equal" }
for i, key in ipairs(wsKeys) do
    hl.bind(mainMod .. " + " .. key,         function() switch_to_ws(i) end)
    hl.bind(mainMod .. " + SHIFT + " .. key, function() move_to_ws(i)   end)
end

-- Mouse workspace scroll
hl.bind(mainMod .. " + mouse_down",     hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",       hl.dsp.focus({ workspace = "e-1" }))

-- Mouse move/resize
hl.bind(mainMod .. " + mouse:272",      hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",      hl.dsp.window.resize(), { mouse = true })

-- ─── Function / Media Keys ───────────────────────────────────────────────────
hl.bind("XF86Calculator",       hl.dsp.exec_cmd("kitty -e python3"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"),             { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"),             { repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer -t"),               { release = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"),     { release = true })
hl.bind("XF86AudioPause",       hl.dsp.exec_cmd("playerctl play-pause"),     { release = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"),           { release = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"),       { release = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl set +5%"),    { repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl set 5%-"),    { repeating = true })
