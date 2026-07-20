hl.config({
    plugin = {
        dynamic_cursors = {
            enabled = true,

            mode = "rotate",
            threshold = 2,

            rotate = {
                length = 22,
                offset = -8,
            },

            stretch = {
                limit = 1800,
            },

            shake = {
                enabled = true,
                threshold = 5,
                base = 3,
                speed = 4,
                timeout = 1200,
                effects = false,
            },

            hyprcursor = {
                enabled = true,
                nearest = false,
            },

            shaperule = {
                "text, none",
                "wait, none",
                "grab, stretch, stretch:limit: 1800",
                "grabbing, stretch, stretch:limit: 1800",
            },
        },
    },
})
