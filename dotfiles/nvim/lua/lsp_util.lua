local M = {}

-- LSP on_attach function with key mappings
M.on_attach = function(client, bufnr)
  local nmap = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end

  -- Key mappings
  nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
  nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
  nmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
  nmap("K", vim.lsp.buf.hover, "Hover Documentation")
  nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
  nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
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

-- Server definitions
M.servers = {
  clangd = {}, -- C/C++
  rust_analyzer = {}, -- Rust
  pylsp = {}, -- Python
  lua_ls = {}, -- Lua
  -- Add more servers as needed
}

-- Generate filetype to server mapping (only if lspconfig is available)
M.filetype_to_server = {}
do
  local ok, lspconfig = pcall(require, "lspconfig")
  if ok and lspconfig then
    for server_name, _ in pairs(M.servers) do
      local cfg = lspconfig[server_name]
      local filetypes = cfg and cfg.document_config and cfg.document_config.default_config.filetypes or {}
      for _, ft in ipairs(filetypes) do
        M.filetype_to_server[ft] = server_name
      end
    end
  end
end

return M
