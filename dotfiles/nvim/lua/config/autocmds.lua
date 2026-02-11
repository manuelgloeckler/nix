-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function seed_ipynb_if_empty(buf, event)
  local bufname = vim.api.nvim_buf_get_name(buf)
  if bufname == "" then
    return
  end
  local minimal = {
    "{",
    "  \"cells\": [],",
    "  \"metadata\": {",
    "    \"kernelspec\": {",
    "      \"display_name\": \"Python 3\",",
    "      \"language\": \"python\",",
    "      \"name\": \"python3\"",
    "    },",
    "    \"language_info\": {",
    "      \"name\": \"python\"",
    "    }",
    "  },",
    "  \"nbformat\": 4,",
    "  \"nbformat_minor\": 5",
    "}",
  }
  local stat = vim.loop.fs_stat(bufname)
  if not stat or stat.size == 0 then
    pcall(vim.fn.writefile, minimal, bufname)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, minimal)
    return
  end
  local line_count = vim.api.nvim_buf_line_count(buf)
  local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  if line_count == 1 and first_line == "" then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, minimal)
  end
end

-- Seed empty .ipynb files with valid JSON so jupytext can parse them.
local ipynb_seed_opts = {
  group = vim.api.nvim_create_augroup("ipynb_seed_json", { clear = true }),
  pattern = { "*.ipynb" },
  callback = function(args)
    seed_ipynb_if_empty(args.buf, args.event)
  end,
}
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, ipynb_seed_opts)

-- Auto-create a project kernelspec and init Molten for .ipynb
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("molten_project_kernelspec_ipynb", { clear = true }),
  pattern = { "*.ipynb" },
  callback = function(args)
    if vim.b._molten_local_venv_inited then
      return
    end
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    local bufdir = bufname ~= "" and (vim.fs.dirname and vim.fs.dirname(bufname) or vim.fn.fnamemodify(bufname, ":p:h")) or vim.fn.getcwd()
    local ok, py = pcall(require, "config.python")
    if ok and py and py.auto_init_molten_kernel_for_ipynb then
      py.auto_init_molten_kernel_for_ipynb(bufdir)
      vim.b._molten_local_venv_inited = true
    end
  end,
})

-- If Molten commands are missing (e.g. provider path changed), register remote plugins.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("ensure_remote_plugins", { clear = true }),
  once = true,
  callback = function()
    if vim.fn.exists(":MoltenInfo") == 0 then
      pcall(function()
        local py = require("config.python")
        py.ensure_venv()
        py.configure_provider()
        py.prepend_venv_bin_to_path()
      end)
      vim.schedule(function()
        vim.cmd("silent! UpdateRemotePlugins")
      end)
    end
  end,
})
