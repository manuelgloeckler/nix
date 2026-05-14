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
    "fang2hou/blink-copilot",
    enabled = false,
  },
}
