-- health_shim.lua
-- Provide compatibility between Neovim 0.9 (report_*) and 0.10+ (no report_*).

local ok, health = pcall(function()
  return vim.health
end)

if ok and health and not health.report_start and type(health.start) == "function" then
  -- Define legacy API in terms of new API so older plugins work.
  health.report_start = function(msg)
    return health.start(msg)
  end
  health.report_ok = function(msg)
    return health.ok(msg)
  end
  health.report_warn = function(msg)
    return health.warn(msg)
  end
  health.report_info = function(msg)
    return health.info(msg)
  end
  health.report_error = function(msg)
    return health.error(msg)
  end
end

return true

