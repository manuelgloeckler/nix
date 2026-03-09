return {
  {
    "LazyVim/LazyVim",
    -- Handle both legacy (boolean) and newer (table with enabled=false) schemas
    opts = function(_, opts)
      opts.news = opts.news or {}

      if type(opts.news.lazyvim) == "table" then
        opts.news.lazyvim.enabled = false
      else
        opts.news.lazyvim = false
      end
      if type(opts.news.neovim) == "table" then
        opts.news.neovim.enabled = false
      else
        opts.news.neovim = false
      end
    end,
  },
}
