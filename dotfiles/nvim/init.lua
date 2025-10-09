-- Require Neovim >= 0.11.2 for latest LazyVim
do
  local v = vim.version and vim.version() or { major = 0, minor = 0, patch = 0 }
  local ok = (v.major > 0)
    or (v.major == 0 and (v.minor > 11 or (v.minor == 11 and v.patch >= 2)))
  if not ok then
    vim.schedule(function()
      vim.notify(
        string.format(
          "LazyVim now requires Neovim >= 0.11.2 (found %d.%d.%d)",
          v.major,
          v.minor,
          v.patch
        ),
        vim.log.levels.ERROR
      )
    end)
  end
end

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
