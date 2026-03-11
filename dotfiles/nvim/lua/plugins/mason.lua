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
      opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
        before_init = function(_, config)
          local py = require("config.python")
          local venv_python = py.resolve_project_python(config.root_dir)
          if not venv_python then
            return
          end
          -- e.g. /project/.venv/bin/python -> venv_dir=/project/.venv
          local venv_dir = vim.fn.fnamemodify(venv_python, ":h:h")
          -- Must mutate in-place: config.settings and client.settings share
          -- the same table reference; replacing config.settings would break it.
          config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
            pythonPath = venv_python,
            venvPath = vim.fn.fnamemodify(venv_dir, ":h"),
            venv = vim.fn.fnamemodify(venv_dir, ":t"),
          })
        end,
        settings = {
          python = {
            analysis = {
              autoImportCompletions = true,
              autoSearchPaths = true,
              diagnosticMode = "openFilesOnly",
              typeCheckingMode = "basic",
              useLibraryCodeForTypes = true,
              disableOrganizeImports = true,
            },
          },
        },
      })
      -- Keep Python LSP predictable: avoid auto-enabling extra servers from Mason.
      opts.servers.pylsp = false
      opts.servers.ruff = false
      return opts
    end,
  },
}
