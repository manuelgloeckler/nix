-- In your plugin configuration
return {
  "mason-org/mason.nvim",
  dependencies = { "mason-org/mason-lspconfig.nvim" },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = vim.tbl_keys(require("lsp_util").servers),
    })
  end,
}
