-- apply a 90° offset in rotate mode to the text shape
hl.plugin.dynamic_cursors.shape_rule { shape = "text", rotate = { offset = 90.0 } }

-- use stretch mode when grabbing, and set the limit low
hl.plugin.dynamic_cursors.shape_rule { shape = "grab", mode = "stretch", stretch = { limit = 2000 } }

-- do not show any effects on clientside cursors
hl.plugin.dynamic_cursors.shape_rule { shape = "clientside", mode = "none" }
