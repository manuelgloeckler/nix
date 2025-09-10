-- In your plugin configuration
return {
  "mason-org/mason.nvim",
  dependencies = { "mason-org/mason-lspconfig.nvim" },
  config = function()
    pcall(function()
      -- Ensure Neovim uses the venv python for provider; do not alter PATH used by Mason installers.
      require("config.python").configure_provider()
    end)
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = vim.tbl_keys(require("lsp_util").servers),
    })
  end,
}
