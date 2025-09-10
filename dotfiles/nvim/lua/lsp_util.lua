-- lsp_util.lua
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

-- LSP capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Server definitions
M.servers = {
  clangd = {}, -- C/C++
  rust_analyzer = {}, -- Rust
  pylsp = {}, -- Python
  lua_ls = {}, -- Lua
  -- Add more servers as needed
}

-- Generate filetype to server mapping
M.filetype_to_server = {}
for server_name, _ in pairs(M.servers) do
  local filetypes = require("lspconfig")[server_name].document_config.default_config.filetypes or {}
  for _, ft in ipairs(filetypes) do
    M.filetype_to_server[ft] = server_name
  end
end

return M
