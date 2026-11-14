-- Hyprland Lua configuration. Reference: https://wiki.hypr.land/configuring/

local terminal = "kitty"
local menu     = "walker"
local scripts  = os.getenv("HOME") .. "/.config/hypr/scripts"
local mainMod  = "SUPER"

local WORKSPACE_COUNT = 10
local RESIZE_STEP     = 40

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "DP-2", mode = "preferred", position = "0x0",    scale = "auto" })
hl.monitor({ output = "DP-3", mode = "preferred", position = "0x1440", scale = "auto" })
hl.monitor({ output = "",     mode = "preferred", position = "auto",   scale = "auto" })

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd(terminal, { workspace = "2 silent" })
    hl.exec_cmd("google-chrome-stable", { workspace = "1 silent" })
    hl.exec_cmd(os.getenv("HOME") .. "/.config/waybar/launcher.sh")
    hl.exec_cmd("wpaperd")
    hl.exec_cmd("walker --gapplication-service")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 5,
        border_size = 1,
        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 4,
        active_opacity   = 0.9,
        inactive_opacity = 0.6,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur   = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },
    master  = { new_status = "master" },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },

    debug = { vfr = true },
    xwayland = { force_zero_scaling = false },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,in",
        kb_variant = ",guj",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0,
        natural_scroll = true,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            tap_to_click = true,
            middle_button_emulation = true,
            drag_lock = false,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

----------------------
---- WORKSPACES ----
----------------------

local WORKSPACE_NAMES = {
    "web", "terminal", "intellij", "code", "neovide",
    "libreoffice", "music", "misc", "messaging", "10",
}
for i, name in ipairs(WORKSPACE_NAMES) do
    hl.workspace_rule({ workspace = tostring(i), default_name = name })
end

---------------------
---- KEYBINDINGS ----
---------------------

hl.bind(mainMod .. " + Return",       hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D",            hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + Q",    hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + C",    hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E",    hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + Escape",       hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",            hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + W",            hl.dsp.group.toggle())
hl.bind(mainMod .. " + Tab",          hl.dsp.group.next())
hl.bind(mainMod .. " + P",            hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T",            hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + CTRL + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + CTRL + SHIFT + S", hl.dsp.exec_cmd("hyprlock & systemctl suspend"))
hl.bind(mainMod .. " + CTRL + V",         hl.dsp.exec_cmd("openwhispr --toggle-dictation"))
hl.bind(mainMod .. " + CTRL + C",         hl.dsp.exec_cmd("cliphist list | " .. menu .. " --dmenu | cliphist decode | wl-copy"))

local DIRECTIONS = {
    { key = "left",  vim = "H", direction = "left" },
    { key = "right", vim = "L", direction = "right" },
    { key = "up",    vim = "K", direction = "up" },
    { key = "down",  vim = "J", direction = "down" },
}
for _, d in ipairs(DIRECTIONS) do
    for _, key in ipairs({ d.key, d.vim }) do
        hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ direction = d.direction }))
        hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ direction = d.direction }))
    end
    hl.bind(mainMod .. " + CTRL + " .. d.key, hl.dsp.workspace.move({ monitor = d.direction }))
end

for i = 1, WORKSPACE_COUNT do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + S",   hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", "escape", function()
    local steps = {
        { "H", -RESIZE_STEP, 0 }, { "left",  -RESIZE_STEP, 0 },
        { "L",  RESIZE_STEP, 0 }, { "right",  RESIZE_STEP, 0 },
        { "K", 0, -RESIZE_STEP }, { "up",    0, -RESIZE_STEP },
        { "J", 0,  RESIZE_STEP }, { "down",  0,  RESIZE_STEP },
    }
    for _, s in ipairs(steps) do
        hl.bind(s[1], hl.dsp.window.resize({ x = s[2], y = s[3], relative = true }), { repeating = true })
    end
    hl.bind("Return", hl.dsp.submap("reset"))
end)

-- Audio, brightness, media
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(scripts .. "/volume --inc"),        { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(scripts .. "/volume --dec"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(scripts .. "/volume --toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(scripts .. "/volume --toggle-mic"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scripts .. "/backlight --inc"),     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/backlight --dec"),     { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots
hl.bind("Print",                           hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("SHIFT + Print",                   hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + Print",             hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("CTRL + Print",                    hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))
hl.bind("CTRL + SHIFT + Print",            hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("CTRL + " .. mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ name = "idle-inhibit-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

local WORKSPACE_ASSIGNMENTS = {
    { "1",  "^(google-chrome|firefox)$" },
    { "2",  "^(kitty|com.mitchellh.ghostty)$" },
    { "3",  "^(jetbrains-idea-ce|jetbrains-idea|dcvviewer)$" },
    { "4",  "^(DBeaver|code)$" },
    { "5",  "^(neovide)$" },
    { "6",  "^(libreoffice.*)$" },
    { "9",  "^(Slack)$" },
    { "10", "^(amazonconnections)$" },
}
for _, a in ipairs(WORKSPACE_ASSIGNMENTS) do
    hl.window_rule({ name = "assign-ws-" .. a[1], match = { class = a[2] }, workspace = a[1] })
end

hl.window_rule({ name = "zoom-float",     match = { class = "^(zoom)$" }, float = true })
hl.window_rule({ name = "emulator-title", match = { title = "^(Android Emulator.*)$" }, float = true })
hl.window_rule({ name = "emulator-class", match = { class = "^(emulator64-arm|emulator64-x86)$" }, float = true })
hl.window_rule({ name = "center-floating", match = { float = true }, center = true })

hl.window_rule({
    name  = "whispr-overlay",
    match = { class = "^open-whispr$" },
    border_size = 0,
    rounding    = 0,
    no_shadow   = true,
    no_blur     = true,
    no_anim     = true,
    opacity     = "1.0 override 1.0 override",
})
pcall(require, "/home/sahir/.config/hypr/openwhispr-binds.lua")

hl.window_rule({
    name  = "chrome-pip",
    match = { class = "^google-chrome$", title = "^(Picture in picture|Picture-in-Picture|Google Meet|meet\\.google\\.com)$" },
    float = true,
    pin   = true,
    size  = "480 270",
    move  = "monitor_w-window_w-20 monitor_h-window_h-20",
})
