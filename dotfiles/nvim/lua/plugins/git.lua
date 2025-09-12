return {
  -- Neogit: Git UI
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration
      "nvim-telescope/telescope.nvim", -- optional
    },
    config = function()
      require("neogit").setup({})
    end,
    keys = {
      { "<leader>gn", function() require("neogit").open({ kind = "auto" }) end, desc = "Neogit status" },
      { "<leader>gnc", "<cmd>Neogit commit<cr>", desc = "Neogit commit" },
      { "<leader>gnp", "<cmd>Neogit pull<cr>", desc = "Neogit pull" },
      { "<leader>gnP", "<cmd>Neogit push<cr>", desc = "Neogit push" },
      { "<leader>gnl", "<cmd>Neogit log<cr>", desc = "Neogit log" },
    },
  },

  -- Octo: GitHub issues/PRs
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
    keys = {
      { "<leader>goo", "<cmd>Octo actions<cr>", desc = "Octo actions" },
      { "<leader>goi", "<cmd>Octo issue list<cr>", desc = "List issues" },
      { "<leader>gop", "<cmd>Octo pr list<cr>", desc = "List PRs" },
      { "<leader>goc", "<cmd>Octo pr create<cr>", desc = "Create PR" },
      { "<leader>goC", "<cmd>Octo pr checkout<cr>", desc = "Checkout PR" },
      { "<leader>gor", "<cmd>Octo review start<cr>", desc = "Start review" },
    },
  },
}
