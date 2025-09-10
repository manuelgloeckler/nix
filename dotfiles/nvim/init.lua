-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")



-- Built-in OSC52 clipboard (copy-only)
local osc52 = require('vim.ui.clipboard.osc52')

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = osc52.copy('+'),
    ['*'] = osc52.copy('*'),
  },
  -- Do not try to *read* via OSC52 (many terminals disallow it).
  paste = {
    ['+'] = function() return { { '' }, 'v' } end,
    ['*'] = function() return { { '' }, 'v' } end,
  },
  cache_enabled = 0,
}

-- Optional: make all yanks use the + register
-- vim.opt.clipboard = 'unnamedplus'
