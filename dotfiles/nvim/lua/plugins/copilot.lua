return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 150,
        hide_during_completion = false,
        keymap = {
          accept = "<Tab>",
          next = "<M-j>",
          prev = "<M-k>",
          dismiss = "<C-e>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = false,
        gitcommit = false,
        text = false,
      },
    },
  },

  {
    "zbirenbaum/copilot-cmp",
    enabled = false,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}

      opts.sources.default = vim.tbl_filter(function(source)
        return source ~= "copilot"
      end, opts.sources.default or {})

      if opts.sources.providers then
        opts.sources.providers.copilot = nil
      end

      return opts
    end,
  },

  {
    "fang2hou/blink-copilot",
    enabled = false,
  },
}
