return {
  "kawre/leetcode.nvim",
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
  lazy = false,
}
