-- ~/.config/nvim/lua/plugins/ai-keys.lua
return {
  -- Copilot: inline suggestions + leader-based keymaps with desc (so they appear in hints)
  {
    "zbirenbaum/copilot.lua",
    -- Copilot extra is already imported via lazyvim.json
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

  -- Use blink.cmp with the blink-copilot source for richer Copilot items
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "fang2hou/blink-copilot" },
    opts = function(_, opts)
      -- Prefer Copilot when it's confident and show a few strong options
      opts.sources = opts.sources or {}
      opts.sources.default = { "copilot", "lsp", "path", "snippets", "buffer" }
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
          opts = {
            max_completions = 3,
            debounce = 200,
          },
        },
      })

      -- Allow toggling blink.cmp enablement with <leader>aC
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
      vim.g.__blink_toggle = function(on)
        if on == nil then
          enabled = not enabled
        else
          enabled = on
        end
        vim.notify("blink.cmp: " .. (enabled and "enabled" or "disabled"))
      end

      return opts
    end,
    keys = {
      {
        "<leader>aC",
        function()
          if vim.g.__blink_toggle then
            vim.g.__blink_toggle()
          end
        end,
        desc = "AI: Toggle blink.cmp Completions",
        mode = { "n", "i" },
      },
    },
  },
}
