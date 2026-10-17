return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts = opts or {}
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.python = { "ruff" }

      if opts.linters and opts.linters.pycodestyle then
        opts.linters.pycodestyle = nil
      end

      return opts
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}
      -- Pyrefly replaces pyright as the Python type checker.
      -- "auto" migrates nearby mypy/pyright config in memory, else falls back
      -- to the "basic" preset (closest to the old pyright basic setup).
      -- Use "default" or "strict" for fuller squiggles.
      opts.servers.pyrefly = vim.tbl_deep_extend("force", opts.servers.pyrefly or {}, {
        enabled = true,
        before_init = function(_, config)
          local py = require("config.python")
          local venv_python = py.resolve_project_python(config.root_dir)
          if not venv_python then
            return
          end
          -- Pyrefly reads the interpreter from initializationOptions.pythonPath
          -- (top-level, no "python." prefix). Also mirror it into settings
          -- for clients that forward settings instead.
          config.initializationOptions = vim.tbl_deep_extend(
            "force",
            config.initializationOptions or {},
            { pythonPath = venv_python }
          )
          config.settings = config.settings or {}
          config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
            pythonPath = venv_python,
          })
        end,
        initializationOptions = {
          pythonPath = nil, -- filled in by before_init when a project venv is found
          pyrefly = {
            typeCheckingMode = "auto",
          },
        },
      })
      -- Explicitly off: LazyVim's python extra already disables these when
      -- lazyvim_python_lsp = "pyrefly", but keep it deterministic here too.
      opts.servers.pyright = { enabled = false }
      opts.servers.basedpyright = { enabled = false }
      -- Keep Python LSP predictable: avoid auto-enabling extra servers from Mason.
      opts.servers.pylsp = false
      opts.servers.ruff = false
      return opts
    end,
  },
}
