-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

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
