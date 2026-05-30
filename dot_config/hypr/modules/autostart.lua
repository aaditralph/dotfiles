-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpolkitagent")
    hl.exec_cmd("/usr/lib/pam_kwallet_init")
    hl.exec_cmd("kwalletd5")
    hl.exec_cmd("rog-control-center")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hyprpm reload -n")
end)
