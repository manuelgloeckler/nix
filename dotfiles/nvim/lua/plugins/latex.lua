return {
  {
    "let-def/texpresso.vim",
    ft = { "tex", "latex", "plaintex" },
    cmd = { "TeXpresso", "TeXpressoTheme" },
    init = function()
      -- Match the editor theme reasonably well in the texpresso viewer.
      vim.g.texpresso_text_color = { 245, 245, 245 }
      vim.g.texpresso_background_color = { 26, 26, 26 }
    end,
    keys = {
      {
        "<leader>lt",
        function()
          vim.cmd("TeXpresso " .. vim.fn.expand("%:p"))
        end,
        ft = { "tex", "latex" },
        desc = "TeXpresso: live preview current file",
      },
      {
        "<leader>lT",
        "<cmd>TeXpressoTheme<cr>",
        ft = { "tex", "latex" },
        desc = "TeXpresso: re-apply theme colors",
      },
    },
  },
  -- which-key group label
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({ { "<leader>l", group = "LaTeX", icon = "" } })
      end
      return opts
    end,
  },
}
