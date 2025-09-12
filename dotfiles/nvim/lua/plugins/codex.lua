return {
  "johnseth97/codex.nvim",
  lazy = true,
  cmd = { "Codex", "CodexToggle" },
  cond = function()
    local key = vim.env.OPENAI_API_KEY
    return key ~= nil and key ~= ""
  end,
  keys = {
    {
      "<leader>cc",
      function()
        require("codex").toggle()
      end,
      desc = "Toggle Codex popup",
    },
  },
  opts = {
    keymaps = {
      toggle = nil,  -- keep internal default off; we set our own keymap
      quit = "<C-q>",
    },
    border = "rounded",
    width = 0.8,
    height = 0.8,
    model = nil,
    autoinstall = false, -- managed by Nix; do not auto-install
  },
}
