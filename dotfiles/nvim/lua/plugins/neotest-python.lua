-- ~/.config/nvim/lua/plugins/neotest-python.lua
return {
  -- Python adapter
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    keys = {
      {
        "<leader>tu",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Neotest UI",
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug nearest test",
      },
      {
        "<leader>tD",
        function()
          require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" })
        end,
        desc = "Debug current file",
      },
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require("neotest-python")({
          -- Use your project interpreter so pytest + deps resolve
          python = function(root)
            local ok, py = pcall(require, "config.python")
            if ok and py and py.resolve_project_python_or_fallback then
              return py.resolve_project_python_or_fallback(root)
            end
            return (vim.fn.executable("python3") == 1) and "python3" or "python"
          end,

          -- If your tests live in "tests/" (pytest default), no need to change this,
          -- but you can force it if you like:
          -- args = { "--maxfail=1", "-q" },

          -- If your file names are non-standard, override detection:
          -- is_test_file = function(file_path)
          --   return file_path:match("^tests/") and file_path:match("test_.*%.py$|.*_test%.py$")
          -- end,

          -- If you have multiple envs / workspaces, this can help:
          pytest_discover_instances = true,
          -- You can also set env vars (e.g., src layout):
          -- env = { PYTHONPATH = "src" },
        })
      )

      return opts
    end,
  },
}
