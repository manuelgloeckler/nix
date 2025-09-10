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

-- Check if a Python module is importable in the venv
function M.has_module(mod)
  if not M.ensure_venv() then
    return false
  end
  local py = M.python_bin()
  local code = ([[import importlib.util, sys
sys.exit(0) if importlib.util.find_spec(%q) else sys.exit(1)]]):format(mod)
  vim.fn.system({ py, "-c", code })
  return vim.v.shell_error == 0
end

-- Ensure a set of Python modules are installed in the venv.
-- specs: array of strings (module==pip) or tables { module = "name", pip = "package-name" }
function M.ensure_python_modules(specs)
  if not M.ensure_venv() then
    return false
  end
  local to_install = {}
  for _, spec in ipairs(specs or {}) do
    local module, pip
    if type(spec) == "table" then
      module = spec.module or spec[1]
      pip = spec.pip or spec[2] or module
    else
      module = spec
      pip = spec
    end
    if module and not M.has_module(module) then
      table.insert(to_install, pip)
    end
  end
  if #to_install > 0 then
    return M.pip_install(to_install)
  end
  return true
end

-- Find a local .venv python by searching upward from a directory
function M.find_local_venv_python(start_dir)
  local sep = package.config:sub(1, 1)
  local dir = start_dir or vim.fn.getcwd()
  local found = vim.fs and vim.fs.find and vim.fs.find(".venv", { upward = true, type = "directory", path = dir }) or {}
  if #found == 0 then
    return nil
  end
  local venv = found[1]
  local candidates = {}
  if sep == "/" then
    candidates = { venv .. "/bin/python", venv .. "/bin/python3" }
  else
    candidates = { venv .. "\\Scripts\\python.exe" }
  end
  for _, p in ipairs(candidates) do
    if vim.fn.filereadable(p) == 1 or vim.fn.executable(p) == 1 then
      return p
    end
  end
  return nil
end

-- Resolve a project python, preferring activated envs (uv/venv/conda),
-- then falling back to a local .venv found by searching upward.
function M.resolve_project_python(bufdir)
  local sep = package.config:sub(1, 1)
  local venv = vim.env.VIRTUAL_ENV
  if venv and venv ~= "" then
    local cand = sep == "/" and (venv .. "/bin/python") or (venv .. "\\Scripts\\python.exe")
    if vim.fn.filereadable(cand) == 1 or vim.fn.executable(cand) == 1 then
      return cand
    end
  end
  return M.find_local_venv_python(bufdir)
end

-- --- AUTO KERNEL FOR .venv + MOLTEN ---------------------------------------

-- Ensure ipykernel is available in the given python
local function ensure_ipykernel(py)
  if not py then
    return false
  end
  local code = [[import importlib.util,sys; sys.exit(0) if importlib.util.find_spec("ipykernel") else sys.exit(1)]]
  vim.fn.system({ py, "-c", code })
  if vim.v.shell_error ~= 0 then
    vim.fn.system({ py, "-m", "pip", "install", "-q", "ipykernel" })
    if vim.v.shell_error ~= 0 then
      return false
    end
  end
  return true
end

-- Create/refresh a kernelspec that pins to this venv's python
local function ensure_kernelspec(py, kname, dname)
  if not py then
    return nil
  end
  vim.fn.system({ py, "-m", "ipykernel", "install", "--user", "--name", kname, "--display-name", dname })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return kname
end

-- Public: ensure a kernelspec for the project .venv and init Molten with it
function M.auto_init_molten_kernel_for_ipynb(bufdir)
  local py = M.resolve_project_python(bufdir)
  if not py then
    return
  end

  if not ensure_ipykernel(py) then
    return
  end

  local proj = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local kname = "uv-" .. proj
  local dname = "Python (" .. proj .. ")"

  if not ensure_kernelspec(py, kname, dname) then
    return
  end

  -- Initialize Molten with this kernelspec name
  if vim.fn.exists(":MoltenInit") == 2 then
    pcall(vim.cmd, { cmd = "MoltenInit", args = { kname } })
  end
end

return M
