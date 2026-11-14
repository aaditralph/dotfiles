------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1.0",
})

-- Reloading Hyprland clears monitor rules applied at runtime.
hl.on("config.reloaded", function()
	hl.exec_cmd("/usr/bin/systemctl --user try-restart hyprland-battery-refresh.service")
end)

hl.config({
	cursor = {
		no_hardware_cursors = true,
	},
})

-- For orbolay overlay for goofcord
hl.window_rule({
	match = { title = "^(orbolay)$" },
	no_initial_focus = true,
	suppress_event = "activatefocus",
	float = true,
	pin = true,
	center = true,
	no_blur = true,
	no_dim = true,
	no_follow_mouse = true,
	no_shadow = true,
	border_size = 0,
	no_focus = true,
	move = { "monitor_w", "monitor_h" },
	size = { "monitor_w - 5", "monitor_h - 5" },
})
