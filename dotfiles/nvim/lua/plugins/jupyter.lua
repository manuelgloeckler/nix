-- lua/plugins/
-- lua/plugins/notebooks.lua
return {
  -- 0) Bootstrap a Python venv for Neovim provider/Jupyter tools
  {
    name = "python-venv-bootstrap",
    priority = 10000,
    init = function()
      -- point provider to venv python if present
      pcall(function()
        require("config.python").configure_provider()
      end)
    end,
    build = function()
      -- create venv and install jupytext + ipykernel so molten can run notebooks
      local ok, py = pcall(require, "config.python")
      if not ok then
        return
      end
      py.ensure_venv()
      py.pip_install({ "jupytext", "ipykernel" })
    end,
  },
  -- 1) Convert/open/save .ipynb seamlessly
  {
    "GCBallesteros/jupytext.nvim",
    ft = { "ipynb", "py:percent" },
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = true,
    opts = {
      style = "percent", -- open as Python # %% cells
      output_extension = "auto",
      force_ft = "python",
    },
  },
  {
    "bluz71/vim-moonfly-colors",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.syntax("enable")
      vim.cmd.colorscheme("moonfly")

      vim.api.nvim_set_hl(0, "MoltenOutputBorder", { link = "Normal" })
      vim.api.nvim_set_hl(0, "MoltenOutputBorderFail", { link = "MoonflyCrimson" })
      vim.api.nvim_set_hl(0, "MoltenOutputBorderSuccess", { link = "MoonflyBlue" })
    end,
  },

  -- 2) Run cells with rich output (images, HTML)
  {
    "benlubas/molten-nvim", -- molten (recommended over magma)
    version = "*",
    lazy = false,
    build = ":UpdateRemotePlugins",
    init = function()
      -- make sure provider points at our venv
      pcall(function()
        require("config.python").configure_provider()
      end)
    end,
    init = function()
      -- Optional UI tweaks
      vim.g.molten_image_provider = "image.nvim" -- if you use image.nvim
      vim.g.molten_wrap_output = true
      vim.g.molten_auto_image_popup = false
      vim.g.molten_auto_open_output = false
      vim.g.molten_output_crop_border = false
      vim.g.molten_output_virt_lines = true
      vim.g.molten_output_win_max_height = 50
      vim.g.molten_output_win_style = "minimal"
      vim.g.molten_output_win_hide_on_leave = false
      vim.g.molten_virt_text_output = true
      -- vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_virt_text_max_lines = 10000
      vim.g.molten_cover_empty_lines = false
      --vim.g.molten_copy_output = true
    end,
    config = function()
      -- Handy keymaps (change <leader>m to taste)
      vim.keymap.set("n", "<leader>mi", ":MoltenInit python3<CR>", { desc = "Molten: init python kernel" })
      vim.keymap.set("n", "<leader>mr", ":MoltenEvaluateLine<CR>", { desc = "Molten: run line" })
      vim.keymap.set("x", "<leader>mr", ":<C-u>MoltenEvaluateVisual<CR>", { desc = "Molten: run selection" })
      vim.keymap.set("n", "<leader>mc", ":MoltenReevaluateCell<CR>", { desc = "Molten: rerun cell" })
      vim.keymap.set("n", "<leader>mo", ":MoltenEnterOutput<CR>", { desc = "Molten: focus output" })
      vim.keymap.set("n", "<leader>md", ":MoltenDelete<CR>", { desc = "Molten: clear cell/output" })
    end,
  },
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty", -- change to \"ueberzug\", \"sixel\", etc. if not on Kitty
      rocks = { "magick" },
      integrations = {
        markdown = { enabled = true },
        neorg = { enabled = true },
        html = { enabled = true },
        css = { enabled = true },
      },
      max_width = 500,
      max_height = 500,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = false,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },
  {
    "GCBallesteros/NotebookNavigator.nvim",
    dependencies = { "benlubas/molten-nvim" },
    opts = {
      cells = { "jupytext" }, -- recognizes # %% cells
      strategy = "molten",    -- send to molten
    },
    keys = {
      {
        "jc",
        function()
          require("notebook-navigator").move_cell("d")
        end,
        desc = "Next cell",
      },
      {
        "kc",
        function()
          require("notebook-navigator").move_cell("u")
        end,
        desc = "Prev cell",
      },
      {
        "<leader>mc",
        function()
          require("notebook-navigator").run_cell()
        end,
        desc = "Run cell",
      },
      {
        "<leader>mn",
        function()
          require("notebook-navigator").run_and_move()
        end,
        desc = "Run + next",
      },
    },
  },
}
