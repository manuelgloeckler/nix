-- Handy CopilotChat shortcuts for file/selection questions
return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    keys = {
      -- Ask about the current file (adds sticky buffer context)
      {
        "<leader>a?",
        function()
          -- autosave current buffer before asking
          if vim.bo.modified then
            pcall(vim.cmd, "silent write")
          end
          require("CopilotChat").ask(
            "> #buffer:active\nExplain this file briefly, then point out issues."
          )
        end,
        mode = "n",
        desc = "CopilotChat: Ask about current file",
      },
      -- Ask about the current selection
      {
        "<leader>a?",
        function()
          -- autosave current buffer before asking (useful if selection edits just happened)
          if vim.bo.modified then
            pcall(vim.cmd, "silent write")
          end
          require("CopilotChat").ask("Explain this selection and suggest improvements.")
        end,
        mode = "x",
        desc = "CopilotChat: Ask about selection",
      },
    },
  },

  -- Extend CopilotChat with resources/autosave preference (merged into LazyVim's config)
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.resources = opts.resources or {}
      -- Enable autosave behavior in resources (if supported by plugin); safe no-op otherwise
      opts.resources.autosave = true
      return opts
    end,
  },

  -- Ensure which-key shows an "AI" group for <leader>a
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, wk = pcall(require, "which-key")
      if not ok then
        return opts
      end
      wk.add({
        { "<leader>a", group = "AI" },
      })
      return opts
    end,
  },
}
