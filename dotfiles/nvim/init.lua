-- Configure Python provider venv early so plugin builds use it
pcall(function()
  local py = require("config.python")
  py.configure_provider()
end)

require("config.lazy")



-- Built-in OSC52 clipboard (copy-only)
local has_osc52, osc52 = pcall(require, 'vim.ui.clipboard.osc52')

if has_osc52 then
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
end

-- Optional: make all yanks use the + register
-- vim.opt.clipboard = 'unnamedplus'
