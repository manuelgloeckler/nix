-- ~/.config/nvim/lua/plugins/ai-keys.lua
return {
  -- Copilot: inline suggestions + leader-based keymaps with desc (so they appear in hints)
  {
    "zbirenbaum/copilot.lua",
    -- if you haven't imported the Copilot extra yet, you can also add:
    -- dependencies = { { import = "lazyvim.plugins.extras.coding.copilot" } },
    keys = {
      {
        "<leader>aA",
        function()
          require("copilot.suggestion").toggle_auto_trigger()
        end,
        desc = "AI: Toggle Copilot Autosuggest",
        mode = { "n", "i" },
      },
      {
        "<leader>aj",
        function()
          require("copilot.suggestion").next()
        end,
        desc = "AI: Next Suggestion",
        mode = { "n", "i" },
      },
      {
        "<leader>ak",
        function()
          require("copilot.suggestion").prev()
        end,
        desc = "AI: Prev Suggestion",
        mode = { "n", "i" },
      },
      {
        "<leader>ax",
        function()
          require("copilot.suggestion").dismiss()
        end,
        desc = "AI: Dismiss Suggestion",
        mode = { "n", "i" },
      },
    },
  },

  -- Toggle the regular completion popup (nvim-cmp) under <leader>a as well
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    opts = function(_, opts)
      local enabled = true
      local prev_enabled = opts.enabled
      if type(prev_enabled) ~= "function" then
        prev_enabled = function()
          return prev_enabled ~= false
        end
      end
      opts.enabled = function()
        return enabled and prev_enabled()
      end
      vim.g.__cmp_toggle = function(on)
        if on == nil then
          enabled = not enabled
        else
          enabled = on
        end
        vim.notify("nvim-cmp: " .. (enabled and "enabled" or "disabled"))
      end
      return opts
    end,
    keys = {
      {
        "<leader>aC",
        function()
          if vim.g.__cmp_toggle then
            vim.g.__cmp_toggle()
          end
        end,
        desc = "AI: Toggle nvim-cmp Completions",
        mode = { "n", "i" },
      },
    },
  },
}
