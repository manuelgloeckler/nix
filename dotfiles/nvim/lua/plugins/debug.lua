-- ~/.config/nvim/lua/plugins/python-dap.lua
return {
  -- Core DAP + UI defaults
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- required by dap-ui
      "theHamsta/nvim-dap-virtual-text", -- optional but nice
    },
    keys = {
      { "<F5>", function() require("dap").continue() end,               desc = "Debug: Continue" },
      { "<F10>", function() require("dap").step_over() end,             desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end,             desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end,              desc = "Debug: Step Out" },
      { "<leader>dc", function() require("dap").continue() end,          desc = "Debug: Continue" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        desc = "Debug: Conditional Breakpoint",
      },
      { "<leader>do", function() require("dap").step_over() end,         desc = "Debug: Step Over" },
      { "<leader>di", function() require("dap").step_into() end,         desc = "Debug: Step Into" },
      { "<leader>dr", function() require("dap").repl.open() end,         desc = "Debug: Open REPL" },
      { "<leader>dl", function() require("dap").run_last() end,          desc = "Debug: Run Last" },
      { "<leader>du", function() require("dapui").toggle() end,          desc = "Debug: Toggle UI" },
      { "<leader>de", function() require("dapui").eval() end,            desc = "Debug: Eval" },
      { "<leader>de", function() require("dapui").eval() end,            desc = "Debug: Eval Selection", mode = "v" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.40 },
              { id = "breakpoints", size = 0.20 },
              { id = "stacks", size = 0.20 },
              { id = "watches", size = 0.20 },
            },
            size = 45,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 0.50 },
              { id = "console", size = 0.50 },
            },
            size = 12,
            position = "bottom",
          },
        },
        floating = {
          max_height = 0.9,
          max_width = 0.9,
          border = "rounded",
          mappings = { close = { "q", "<Esc>" } },
        },
      })

      require("nvim-dap-virtual-text").setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })
    end,
  },

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
    keys = {
      { "<leader>tm", function() require("dap-python").test_method() end, desc = "Test: Debug Method" },
      { "<leader>tc", function() require("dap-python").test_class() end,  desc = "Test: Debug Class" },
      { "<leader>tf", function() require("dap-python").test_run() end,    desc = "Test: Debug File" },
    },
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

  -- Ensure which-key shows groups for debug/test leader keys
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<leader>d", group = "Debug" },
          { "<leader>t", group = "Test" },
        })
      end
      return opts
    end,
  },

}
