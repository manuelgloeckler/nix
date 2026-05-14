return {
  "johnseth97/codex.nvim",
  lazy = true,
  cmd = { "Codex", "CodexToggle" },
  keys = {
    {
      "<leader>aO",
      function()
        require("codex").toggle()
      end,
      desc = "Toggle Codex popup",
    },
    {
      "<D-M-C-c>",
      function()
        require("codex").toggle()
      end,
      desc = "Toggle Codex (Super+c)",
      mode = { "n", "t" },
    },
  },
  opts = {
    keymaps = {
      toggle = nil, -- keep internal default off; we set our own keymap
      quit = "q",
    },
    border = "rounded",
    width = 0.8,
    height = 0.8,
    model = nil,
    autoinstall = true, -- let plugin install @openai/codex if missing
  },
}
