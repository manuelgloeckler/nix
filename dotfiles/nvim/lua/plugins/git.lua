return {
  -- Primary git UI: terminal lazygit in a float
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

  -- Diffview: the missing piece lazygit doesn't have. During a merge conflict,
  -- `:DiffviewOpen` (no args) shows a 3-pane LOCAL | merged | REMOTE view.
  -- Outside a merge it's a clean "tree of changed files + diff" workflow,
  -- and `DiffviewFileHistory` is a great file-level git log.
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles",
      "DiffviewRefresh", "DiffviewFileHistory",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open (3-way during merge)" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: current file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: repo history" },
      {
        "<leader>gM",
        function()
          -- Compare current branch against the default branch tip
          local default = vim.fn.systemlist("git symbolic-ref refs/remotes/origin/HEAD --short")[1]
          default = default and default:gsub("^origin/", "") or "main"
          vim.cmd("DiffviewOpen origin/" .. default .. "...HEAD")
        end,
        desc = "Diffview: vs origin/main",
      },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed", -- LOCAL | merged | REMOTE
          disable_diagnostics = true,
        },
      },
    },
  },

  -- git-conflict: per-hunk choose-ours/theirs/both inside the buffer.
  -- Pairs naturally with diffview's merge tool.
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPre",
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      highlights = { incoming = "DiffAdd", current = "DiffText" },
    },
    keys = {
      { "<leader>gco", "<cmd>GitConflictChooseOurs<cr>", desc = "Conflict: choose ours" },
      { "<leader>gct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Conflict: choose theirs" },
      { "<leader>gcb", "<cmd>GitConflictChooseBoth<cr>", desc = "Conflict: choose both" },
      { "<leader>gcn", "<cmd>GitConflictChooseNone<cr>", desc = "Conflict: choose none" },
      { "<leader>gcq", "<cmd>GitConflictListQf<cr>", desc = "Conflicts → quickfix" },
      { "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next conflict" },
      { "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev conflict" },
    },
  },

  -- Octo: GitHub issues/PRs (kept — separate concern from local git)
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      enable_builtin = true,
      default_merge_method = "squash",
      -- Most-recently-updated first when listing PRs/issues — matches how
      -- you'd triage on github.com.
      pull_requests = {
        order_by = { field = "UPDATED_AT", direction = "DESC" },
      },
      issues = {
        order_by = { field = "UPDATED_AT", direction = "DESC" },
      },
      -- Stop the "missing scope: read:project" warning that fires for repos
      -- without ProjectsV2 enabled (most repos).
      suppress_missing_scope = { projects_v2 = true },
    },
    keys = {
      -- Disable LazyVim's util.octo extra defaults so our <leader>go* prefix
      -- owns the namespace cleanly.
      { "<leader>gi", false },
      { "<leader>gI", false },
      { "<leader>gp", false },
      { "<leader>gP", false },
      { "<leader>gr", false },
      { "<leader>gs", false },

      { "<leader>go", desc = "+Octo" },
      { "<leader>goo", "<cmd>Octo actions<cr>", desc = "Actions menu" },

      -- PRs
      { "<leader>gop", "<cmd>Octo pr list<cr>", desc = "List PRs" },
      { "<leader>goP", "<cmd>Octo pr search<cr>", desc = "Search PRs" },
      { "<leader>goc", "<cmd>Octo pr create<cr>", desc = "Create PR" },
      { "<leader>goC", "<cmd>Octo pr checkout<cr>", desc = "Checkout PR" },
      { "<leader>gom", "<cmd>Octo pr merge squash<cr>", desc = "Merge PR (squash)" },

      -- Reviews
      { "<leader>gor", "<cmd>Octo review start<cr>", desc = "Review: start" },
      { "<leader>goR", "<cmd>Octo review resume<cr>", desc = "Review: resume" },
      { "<leader>gos", "<cmd>Octo review submit<cr>", desc = "Review: submit" },
      { "<leader>goD", "<cmd>Octo review discard<cr>", desc = "Review: discard" },

      -- Issues
      { "<leader>goi", "<cmd>Octo issue list<cr>", desc = "List issues" },
      { "<leader>goI", "<cmd>Octo issue search<cr>", desc = "Search issues" },
      { "<leader>goN", "<cmd>Octo issue create<cr>", desc = "New issue" },

      -- Repo / browse
      { "<leader>gob", "<cmd>Octo repo browser<cr>", desc = "Open in browser" },
    },
  },

  -- which-key group labels
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<leader>g", group = "Git" },
          { "<leader>gc", group = "Conflict" },
          { "<leader>go", group = "Octo" },
        })
      end
      return opts
    end,
  },
}
