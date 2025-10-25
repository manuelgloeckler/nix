-- General autosave plugin (LazyVim-friendly)
-- Adds modern autosave behavior across normal buffers
return {
  "okuuva/auto-save.nvim",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    enabled = true,
    debounce_delay = 1000, -- ms
    trigger_events = { "BufLeave", "FocusLost", "InsertLeave", "TextChanged" },
    condition = function(buf)
      -- Only autosave normal files, not things like Neo-tree or Telescope
      local fn = vim.fn
      if fn.getbufvar(buf, "&modifiable") == 0 then
        return false
      end
      local ft = vim.bo[buf].filetype
      local ignore = { "neo-tree", "TelescopePrompt", "lazy", "dashboard" }
      return not vim.tbl_contains(ignore, ft)
    end,
  },
}

