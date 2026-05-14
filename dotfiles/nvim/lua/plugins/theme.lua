-- Set Ayu (dark) as the default colorscheme
return {
  -- Tell LazyVim to use ayu-dark
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu-dark",
    },
  },

  {
    "Shatur/neovim-ayu",
    name = "ayu",
    priority = 1000,
    opts = {
      mirage = false,
      terminal = true,
      overrides = {},
    },
  },
}
