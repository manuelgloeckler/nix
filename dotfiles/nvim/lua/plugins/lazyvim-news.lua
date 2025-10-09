return {
  {
    "LazyVim/LazyVim",
    -- Handle both legacy (boolean) and newer (table with enabled=false) schemas
    opts = function(_, opts)
      opts.news = opts.news or {}

      -- Always set boolean flags (legacy schema)
      opts.news.lazyvim = false
      opts.news.neovim = false

      -- If a newer schema is used where these are tables, force enabled=false
      if type(opts.news.lazyvim) == "table" then
        opts.news.lazyvim.enabled = false
      end
      if type(opts.news.neovim) == "table" then
        opts.news.neovim.enabled = false
      end
    end,
  },
}
