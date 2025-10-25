-- ~/.config/nvim/lua/plugins/python-dap.lua
return {
  -- Make sure the Python adapter (debugpy) is installed
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "debugpy") then
        table.insert(opts.ensure_installed, "debugpy")
      end
      return opts
    end,
  },

  -- DAP for Python with smart interpreter resolution
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      -- Resolve the debugpy adapter python from Mason if available, with fallbacks
      local debugpy_python
      local ok_mason, mason_registry = pcall(require, "mason-registry")
      if ok_mason then
        local ok_pkg, pkg = pcall(mason_registry.get_package, "debugpy")
        if ok_pkg and pkg and type(pkg.get_install_path) == "function" then
          debugpy_python = pkg:get_install_path() .. "/venv/bin/python"
        else
          local ok_settings, mason_settings = pcall(require, "mason.settings")
          if ok_settings and mason_settings.current and mason_settings.current.install_root_dir then
            debugpy_python = mason_settings.current.install_root_dir .. "/packages/debugpy/venv/bin/python"
          end
        end
      end
      if not debugpy_python or vim.fn.executable(debugpy_python) ~= 1 then
        debugpy_python = (vim.fn.executable("python3") == 1) and "python3" or "python"
      end

      require("dap-python").setup(debugpy_python)
      require("dap-python").test_runner = "pytest"

      -- Helper to pick the *project* interpreter for your code (not the adapter)
      local function project_python()
        -- 1) Activated venv
        local venv = os.getenv("VIRTUAL_ENV")
        if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
          return venv .. "/bin/python"
        end
        -- 2) .venv or venv in project
        local cwd = vim.fn.getcwd()
        local candidates = { ".venv/bin/python", "venv/bin/python" }
        for _, p in ipairs(candidates) do
          if vim.fn.executable(cwd .. "/" .. p) == 1 then
            return cwd .. "/" .. p
          end
        end
        -- 3) Poetry
        if vim.fn.executable("poetry") == 1 then
          local ok, path = pcall(function()
            return vim.fn.systemlist("poetry env info -p")[1]
          end)
          if ok and path and vim.fn.executable(path .. "/bin/python") == 1 then
            return path .. "/bin/python"
          end
        end
        -- 4) Fallback
        return (vim.fn.executable("python3") == 1) and "python3" or "python"
      end

      -- Override default configs to use our interpreter resolver
      local dap = require("dap")
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          console = "integratedTerminal",
          justMyCode = true,
          pythonPath = project_python,
        },
        {
          type = "python",
          request = "launch",
          name = "Module (python -m ...)",
          module = function()
            return vim.fn.input("Module to run: ")
          end,
          args = function()
            local a = vim.fn.input("Args: ")
            return (a == "" and {}) or vim.split(a, " ")
          end,
          console = "integratedTerminal",
          justMyCode = true,
          pythonPath = project_python,
        },
        {
          type = "python",
          request = "attach",
          name = "Attach to debugpy",
          connect = function()
            local host = vim.fn.input("Host [127.0.0.1]: ")
            local port = tonumber(vim.fn.input("Port: "))
            return { host = host ~= "" and host or "127.0.0.1", port = port }
          end,
          pythonPath = project_python,
        },
      }
    end,
  },
}
