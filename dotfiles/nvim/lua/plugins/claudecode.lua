return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal = {
        provider = "snacks",
        -- snacks.terminal expects window opts nested under `win`; flat keys
        -- get silently ignored and you get the default split layout.
        -- Mirror the opencode.nvim sizing (88% × 82%, rounded float).
        snacks_win_opts = {
          win = {
            position = "float",
            width = 0.88,
            height = 0.82,
            border = "rounded",
          },
        },
      },
    },
    keys = {
      {
        "<D-M-C-l>",
        function()
          require("claudecode").toggle()
        end,
        desc = "Toggle Claude Code (Super+l)",
        mode = { "n", "t" },
      },
    },
  },
}
