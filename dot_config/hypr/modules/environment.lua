-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("AQ_NO_MODIFIERS", "1")
hl.env("AQ_MGPU_NO_EXPLICIT", "1")
hl.env("AQ_DRM_DEVICES", "/dev/dri/intel_card:/dev/dri/nvidia_card")
-- ---env = XCURSOR_SIZE,24
-- env = HYPRCURSOR_SIZE,24
-- env = XDG_CURRENT_DESKTOP,Hyprland
-- env = XDG_SESSION_TYPE,wayland
-- env = XDG_SESSION_DESKTOP,Hyprland
-- env = QT_QPA_PLATFORMTHEME,hyprqt6engine
-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--     ecosystem = {
--         enforce_permissions = true,
--     },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/usr/bin/hyprpm", "plugin", "allow")
