-- ~/.config/nvim/lua/plugins/neotest-python.lua
return {
  -- Python adapter
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = function(_, opts)
      -- Interpreter resolver that prefers your project venv/Poetry env
      local function project_python()
        local cwd = vim.fn.getcwd()
        local env = os.getenv("VIRTUAL_ENV")
        if env and vim.fn.executable(env .. "/bin/python") == 1 then
          return env .. "/bin/python"
        end
        local candidates = { cwd .. "/.venv/bin/python", cwd .. "/venv/bin/python" }
        for _, p in ipairs(candidates) do
          if vim.fn.executable(p) == 1 then
            return p
          end
        end
        if vim.fn.executable("poetry") == 1 then
          local ok, path = pcall(function()
            return vim.fn.systemlist("poetry env info -p")[1]
          end)
          if ok and path and vim.fn.executable(path .. "/bin/python") == 1 then
            return path .. "/bin/python"
          end
        end
        return (vim.fn.executable("python3") == 1) and "python3" or "python"
      end

      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require("neotest-python")({
          -- Use your project interpreter so pytest + deps resolve
          python = project_python(),

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
