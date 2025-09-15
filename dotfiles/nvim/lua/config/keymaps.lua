-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ~/.config/nvim/lua/plugins/python-dap-keys.lua
return {
  -- Make sure DAP is present
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>dc", function() require("dap").continue() end,          desc = "Debug: Continue" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      { "<leader>do", function() require("dap").step_over() end,         desc = "Debug: Step Over" },
      { "<leader>di", function() require("dap").step_into() end,         desc = "Debug: Step Into" },
      { "<leader>du", function() require("dapui").toggle() end,          desc = "Debug: Toggle UI" },
    },
  },

  -- Python test helpers (will only show in Python buffers)
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    keys = {
      { "<leader>tm", function() require("dap-python").test_method() end, desc = "Test: Debug Method" },
      { "<leader>tc", function() require("dap-python").test_class() end,  desc = "Test: Debug Class" },
      { "<leader>tf", function() require("dap-python").test_run() end,    desc = "Test: Debug File" },
    },
  },

  -- Optional: ensure the groups are named nicely in which-key
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>d"] = { name = "+debug" },
        ["<leader>t"] = { name = "+test" },
      },
    },
  },
}
