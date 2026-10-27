-- Herdr integration: code annotations you send to any agent in the workspace.
-- Pairs with the herdr-side plugin (ChmaraX/herdr-nvim) that provides the nvim
-- sidebar + file picker; installed via home.activation.herdrPlugins in flake.nix.
-- Keymaps live under <leader>ah to avoid colliding with opencode's <leader>a*.
return {
  {
    "ChmaraX/herdr-nvim",
    event = "VeryLazy",
    opts = {
      prefix = "<leader>ah",
      keymaps = true,
      clear_after_send = true,
    },
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
        { "<leader>ah", group = "herdr" },
      })
      return opts
    end,
  },
}
