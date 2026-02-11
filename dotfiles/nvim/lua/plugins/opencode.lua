return {
  {
    "nickjvandyke/opencode.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>ao",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle OpenCode",
        mode = "n",
      },
      {
        "<leader>aa",
        function()
          require("opencode").ask("@this: ", { submit = true })
        end,
        desc = "Ask OpenCode",
        mode = { "n", "x" },
      },
      {
        "<leader>as",
        function()
          require("opencode").select()
        end,
        desc = "OpenCode Actions",
        mode = { "n", "x" },
      },
      {
        "<leader>af",
        function()
          require("opencode").prompt("explain @buffer")
        end,
        desc = "OpenCode Explain File",
        mode = "n",
      },
      {
        "<leader>av",
        function()
          require("opencode").prompt("review @this")
        end,
        desc = "OpenCode Review Selection",
        mode = "x",
      },
      {
        "<leader>ai",
        function()
          require("opencode").command("session.interrupt")
        end,
        desc = "OpenCode Interrupt",
        mode = { "n", "t" },
      },
      {
        "<D-M-C-o>",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle OpenCode (Super+o)",
        mode = { "n", "t" },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          anti_conceal = { enabled = false },
          file_types = { "markdown", "opencode_output" },
        },
        ft = { "markdown", "Avante", "opencode_output" },
      },
      "saghen/blink.cmp",
    },
    init = function()
      vim.o.autoread = true
      vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, {
        keymap_prefix = "<leader>a",
        provider = {
          enabled = "snacks",
          snacks = {
            win = {
              position = "float",
              width = 0.88,
              height = 0.82,
              border = "rounded",
              enter = false,
            },
          },
        },
      })
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, wk = pcall(require, "which-key")
      if not ok then
        return opts
      end
      wk.add({
        { "<leader>a", group = "AI" },
      })
      return opts
    end,
  },
}
