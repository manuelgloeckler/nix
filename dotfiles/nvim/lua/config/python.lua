-- config/python.lua
-- Lightweight helper to manage a Neovim-specific Python venv for providers/plugins.

local M = {}

local sep = package.config:sub(1, 1)
local function join(...)
  return table.concat({ ... }, sep)
end

function M.venv_dir()
  return join(vim.fn.stdpath("data"), "python-venv")
end

function M.venv_bin()
  return join(M.venv_dir(), "bin")
end

function M.python_bin()
  return join(M.venv_bin(), "python3")
end

function M.exists(path)
  return (vim.uv or vim.loop).fs_stat(path) ~= nil
end

-- Create venv if missing using system python3
function M.ensure_venv()
  if not M.exists(M.python_bin()) then
    vim.fn.mkdir(M.venv_dir(), "p")
    local out = vim.fn.system({ "python3", "-m", "venv", M.venv_dir() })
    if vim.v.shell_error ~= 0 then
      vim.schedule(function()
        vim.notify("Failed to create Python venv: " .. out, vim.log.levels.ERROR)
      end)
      return false
    end
  end
  return true
end

-- Install a list of python packages into the venv
function M.pip_install(pkgs)
  if not M.ensure_venv() then
    return false
  end
  local py = M.python_bin()
  -- Upgrade pip/setuptools/wheel quietly
  vim.fn.system({ py, "-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel" })
  if vim.v.shell_error ~= 0 then
    return false
  end
  local args = { py, "-m", "pip", "install" }
  for _, p in ipairs(pkgs or {}) do
    table.insert(args, p)
  end
  vim.fn.system(args)
  return vim.v.shell_error == 0
end

-- Ensure Neovim uses the venv python for remote plugins
function M.configure_provider()
  local py = M.python_bin()
  if M.exists(py) then
    vim.g.python3_host_prog = py
  end
end

-- Prepend venv bin to PATH for current session (does not persist)
function M.prepend_venv_bin_to_path()
  local bin = M.venv_bin()
  if not M.exists(bin) then
    return
  end
  local path = vim.env.PATH or ""
  local delim = (sep == "\\") and ";" or ":"
  if not path:find(vim.pesc(bin), 1, true) then
    vim.env.PATH = bin .. delim .. path
  end
end

return M

