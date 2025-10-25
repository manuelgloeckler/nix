local M = {}

-- LSP on_attach function with key mappings
M.on_attach = function(client, bufnr)
  local nmap = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end
  local vmap = function(keys, func, desc)
    vim.keymap.set("v", keys, func, { buffer = bufnr, desc = desc })
  end

  -- Key mappings
  nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
  nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
  nmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
  nmap("K", vim.lsp.buf.hover, "Hover Documentation")
  nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
  nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  -- Code: Rename (normal + visual). Shows in which-key under <leader>c
  vim.keymap.set({ "n", "v" }, "<leader>cr", vim.lsp.buf.rename, {
    buffer = bufnr,
    desc = "[C]ode: [R]ename",
  })
end

-- LSP capabilities (guarded if cmp_nvim_lsp isn't available yet)
local capabilities = vim.lsp.protocol.make_client_capabilities()
do
  local ok, cmp_caps = pcall(require, "cmp_nvim_lsp")
  if ok and cmp_caps and cmp_caps.default_capabilities then
    M.capabilities = cmp_caps.default_capabilities(capabilities)
  else
    M.capabilities = capabilities
  end
end

-- prefer LSP-based folding if supported
M.capabilities.textDocument = M.capabilities.textDocument or {}
M.capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

-- Server definitions
M.servers = {
  clangd = {}, -- C/C++
  rust_analyzer = {}, -- Rust
  pyright = {}, -- Python (align with LazyVim default)
  lua_ls = {}, -- Lua
  -- Add more servers as needed
}

-- Generate filetype to server mapping (only if lspconfig is available)
M.filetype_to_server = M.filetype_to_server or {}

return M
