return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal = {
        provider = "snacks",
        -- claudecode merges `snacks_win_opts` directly into snacks' `win` table,
        -- so these keys must be flat (NOT nested under another `win`, unlike
        -- opencode.nvim). Mirror the opencode sizing (88% × 82%, rounded float).
        snacks_win_opts = {
          position = "float",
          width = 0.88,
          height = 0.82,
          border = "rounded",
        },
      },
    },
    keys = {
      {
        "<D-M-C-l>",
        "<cmd>ClaudeCode<cr>",
        desc = "Toggle Claude Code (Super+l)",
        mode = { "n", "t" },
      },
    },
  },
}
