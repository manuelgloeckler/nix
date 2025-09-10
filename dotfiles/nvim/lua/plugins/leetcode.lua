return {
  "kawre/leetcode.nvim",
  cmd = { "Leet" },
  keys = {
    { "<leader>Ll", "<cmd>Leet<cr>", desc = "Leet: Open" },
  },
  build = function()
    -- Ensure treesitter is updated for html
    vim.cmd(":TSUpdate html")
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    -- Configuration for leetcode.nvim
    ---@type lc.lang
    lang = "python",
  },
}
