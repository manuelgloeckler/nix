return {
  -- git-conflict.nvim: visualise and resolve merge conflicts
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
    keys = {
      { "<leader>gco", "<cmd>GitConflictChooseOurs<cr>", desc = "Conflict: choose ours" },
      { "<leader>gct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Conflict: choose theirs" },
      { "<leader>gcb", "<cmd>GitConflictChooseBoth<cr>", desc = "Conflict: choose both" },
      { "<leader>gcn", "<cmd>GitConflictChooseNone<cr>", desc = "Conflict: choose none" },
      { "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next conflict" },
      { "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev conflict" },
      { "<leader>gcq", "<cmd>GitConflictListQf<cr>", desc = "Conflicts → quickfix" },
    },
  },

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
      -- Common git actions
      { "<leader>gs", function() require("neogit").open({ kind = "auto" }) end, desc = "Git Status (Neogit)" },
      { "<leader>gn", function() require("neogit").open({ kind = "auto" }) end, desc = "Neogit status" },
      { "<leader>gnc", "<cmd>Neogit commit<cr>", desc = "Neogit commit" },
      { "<leader>gnp", "<cmd>Neogit pull<cr>", desc = "Neogit pull" },
      { "<leader>gnP", "<cmd>Neogit push<cr>", desc = "Neogit push" },
      { "<leader>gnl", "<cmd>Neogit log<cr>", desc = "Neogit log" },
      -- Branch checkout via Telescope
      {
        "<leader>gC",
        function()
          require("telescope.builtin").git_branches()
        end,
        desc = "Checkout branch",
      },
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
    init = function()
      -- extra safety: if anything already mapped <leader>g? for Octo, remove it
      vim.schedule(function()
        local del = function(lhs)
          pcall(vim.keymap.del, "n", lhs)
        end
        for _, k in ipairs({ "<leader>gi", "<leader>gI", "<leader>gp", "<leader>gP", "<leader>gr", "<leader>gs" }) do
          del(k)
        end
      end)
    end,
    opts = {},
    keys = {
      -- remove conflicting default git prefix keys that some presets add
      { "<leader>gi", false }, -- List Issues (Octo)
      { "<leader>gI", false }, -- Search Issues (Octo)
      { "<leader>gp", false }, -- List PRs (Octo)
      { "<leader>gP", false }, -- Search PRs (Octo)
      { "<leader>gr", false }, -- List Repos (Octo)
      { "<leader>gs", false }, -- Search (Octo)

      -- our non-conflicting prefix under g-o
      { "<leader>go", desc = "+Octo" },
      { "<leader>goo", "<cmd>Octo actions<cr>", desc = "Actions" },
      { "<leader>goi", "<cmd>Octo issue list<cr>", desc = "List issues" },
      { "<leader>gop", "<cmd>Octo pr list<cr>", desc = "List PRs" },
      { "<leader>goc", "<cmd>Octo pr create<cr>", desc = "Create PR" },
      { "<leader>goC", "<cmd>Octo pr checkout<cr>", desc = "Checkout PR" },
      { "<leader>gor", "<cmd>Octo review start<cr>", desc = "Start review" },
    },
  },

  -- Which-key group label for Octo prefix
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<leader>go", group = "Octo" },
        })
      end
    end,
  },

  -- Lazygit: terminal UI for Git
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
      { "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file)" },
      { "<leader>gf", "<cmd>LazyGitFilter<cr>", desc = "LazyGit (filter)" },
      { "<leader>gF", "<cmd>LazyGitFilterCurrentFile<cr>", desc = "LazyGit (filter file)" },
    },
  },
}
