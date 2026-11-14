return {
  -- Configure Tokyo Night to be completely transparent
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "moon", -- "storm", "moon", or "night" work great with neon setups
      transparent = true, -- Disables background for normal text windows
      styles = {
        sidebars = "transparent", -- Disables background for file trees (neo-tree)
        floats = "transparent", -- Disables background for popups
      },
      on_highlights = function(hl, c)
        -- Forces borders and floating menus to stay vibrant and visible over your wallpaper
        hl.FloatBorder = { fg = c.cyan, bg = "NONE" }
        hl.NormalFloat = { bg = "NONE" }
        hl.NeoTreeNormal = { bg = "NONE" }
        hl.NeoTreeNormalNC = { bg = "NONE" }
      end,
    },
  },

  -- Tell LazyVim to load it
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
