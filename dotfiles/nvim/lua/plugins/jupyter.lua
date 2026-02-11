-- lua/plugins/
-- lua/plugins/notebooks.lua
return {
  -- 1) Convert/open/save .ipynb seamlessly
  {
    "GCBallesteros/jupytext.nvim",
    ft = { "ipynb", "py:percent" },
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    init = function()
      -- Ensure Neovim uses the venv Python and that the venv bin is on PATH
      local ok, py = pcall(require, "config.python")
      if ok then
        py.configure_provider()
        py.prepend_venv_bin_to_path()
      end
    end,
    build = function()
      -- Create venv and install jupytext in it
      local ok, py = pcall(require, "config.python")
      if not ok then
        return
      end
      py.ensure_venv()
      py.pip_install({ "jupytext" })
      py.configure_provider()
      py.prepend_venv_bin_to_path()
    end,
    config = function(_, opts)
      require("jupytext").setup(opts)
    end,
    opts = {
      style = "percent", -- open as Python # %% cells
      output_extension = "auto",
      force_ft = "python",
    },
  },
  -- Optional theme-related tweaks for molten outputs; no longer enforce a colorscheme here
  {
    "bluz71/vim-moonfly-colors",
    enabled = false,
  },

  -- 2) Run cells with rich output (images, HTML)
  {
    "benlubas/molten-nvim", -- molten (recommended over magma)
    version = "*",
    lazy = false,
    build = function()
      -- Ensure provider and deps, then register remote plugins
      local ok, py = pcall(require, "config.python")
      if ok then
        py.ensure_venv()
        py.configure_provider()
        py.prepend_venv_bin_to_path()
        py.ensure_python_modules({
          "pynvim",
          { module = "jupyter_client", pip = "jupyter-client" },
          "nbformat",
        })
      end
      vim.cmd("silent! UpdateRemotePlugins")
    end,
    init = function()
      -- Ensure provider points at our venv, then UI tweaks
      pcall(function()
        local py = require("config.python")
        py.configure_provider()
        py.prepend_venv_bin_to_path()
      end)
      if vim.fn.exists(":MoltenInstallExtras") == 0 then
        vim.api.nvim_create_user_command("MoltenInstallExtras", function()
          local ok, py = pcall(require, "config.python")
          if not ok then
            return
          end
          local installed = py.ensure_python_modules({
            "cairosvg",
            "pnglatex",
            "plotly",
            "kaleido",
            "pyperclip",
            "pillow",
          })
          vim.notify(
            installed and "Molten extras installed" or "Molten extras install failed",
            installed and vim.log.levels.INFO or vim.log.levels.WARN
          )
        end, { desc = "Install optional Molten python deps" })
      end
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
      -- Handy keymaps (change <leader>j to taste)
      vim.keymap.set("n", "<leader>jU", function()
        local ok, py = pcall(require, "config.python")
        local bufdir = vim.fn.expand("%:p:h")
        local interp = ok and py.resolve_project_python(bufdir) or nil
        if interp and vim.fn.exists(":MoltenInit") == 2 then
          vim.cmd("silent! MoltenInit python3 " .. vim.fn.fnameescape(interp))
        else
          vim.cmd("silent! MoltenInit python3")
        end
      end, { desc = "Molten: init python kernel (project venv if present)" })
      vim.keymap.set("n", "<leader>jr", ":MoltenEvaluateLine<CR>", { desc = "Molten: run line" })
      vim.keymap.set("x", "<leader>jr", ":<C-u>MoltenEvaluateVisual<CR>", { desc = "Molten: run selection" })
      vim.keymap.set("n", "<leader>jc", ":MoltenReevaluateCell<CR>", { desc = "Molten: rerun cell" })
      vim.keymap.set("n", "<leader>jo", ":MoltenEnterOutput<CR>", { desc = "Molten: focus output" })
      vim.keymap.set("n", "<leader>jd", ":MoltenDelete<CR>", { desc = "Molten: clear cell/output" })
      vim.keymap.set("n", "<leader>jR", ":MoltenRestart<CR>", { desc = "Molten: restart kernel" })
      vim.keymap.set("n", "<leader>jI", ":MoltenInterrupt<CR>", { desc = "Molten: interrupt kernel" })
      vim.keymap.set("n", "<leader>jS", ":MoltenShowOutput<CR>", { desc = "Molten: show output" })
      vim.keymap.set("n", "<leader>jH", ":MoltenHideOutput<CR>", { desc = "Molten: hide output" })
      vim.keymap.set("n", "<leader>jK", ":MoltenInfo<CR>", { desc = "Molten: kernel info" })
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
    main = "notebook-navigator",
    opts = {
      cells = { "jupytext" }, -- recognizes # %% cells
      repl_provider = "molten", -- force molten; avoid toggleterm auto-detect
    },
    config = function(_, opts)
      local nn = require("notebook-navigator")
      nn.setup(opts)
      -- Work around nil cell_marker in run_all_cells/run_cells_below for molten.
      local utils = require("notebook-navigator.utils")
      local get_repl = require("notebook-navigator.repls")
      local miniai_spec = require("notebook-navigator.miniai_spec").miniai_spec
      local function cell_marker()
        return utils.get_cell_marker(0, nn.config.cell_markers)
      end
      nn.run_all_cells = function(repl_args)
        local repl = get_repl(nn.config.repl_provider)
        local buf_length = vim.api.nvim_buf_line_count(0)
        return repl(1, buf_length, repl_args, cell_marker())
      end
      nn.run_cells_below = function(repl_args)
        local repl = get_repl(nn.config.repl_provider)
        local buf_length = vim.api.nvim_buf_line_count(0)
        local cell_object = miniai_spec("i", cell_marker())
        return repl(cell_object.from.line, buf_length, repl_args, cell_marker())
      end
    end,
    keys = {
      {
        "]c",
        function()
          require("notebook-navigator").move_cell("d")
        end,
        desc = "Next cell",
      },
      {
        "[c",
        function()
          require("notebook-navigator").move_cell("u")
        end,
        desc = "Prev cell",
      },
      {
        "]C",
        function()
          local nn = require("notebook-navigator")
          local max = vim.api.nvim_buf_line_count(0) + 1
          for _ = 1, max do
            if nn.move_cell("d") == "last" then
              break
            end
          end
        end,
        desc = "Last cell",
      },
      {
        "[C",
        function()
          local nn = require("notebook-navigator")
          local max = vim.api.nvim_buf_line_count(0) + 1
          for _ = 1, max do
            if nn.move_cell("u") == "first" then
              break
            end
          end
        end,
        desc = "First cell",
      },
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
        "<leader>jj",
        function()
          require("notebook-navigator").move_cell("d")
        end,
        desc = "Next cell",
      },
      {
        "<leader>ji",
        function()
          require("notebook-navigator").move_cell("u")
        end,
        desc = "Prev cell",
      },
      {
        "<leader>jX",
        function()
          require("notebook-navigator").run_cell()
        end,
        desc = "Run cell (NotebookNavigator)",
      },
      {
        "<leader>jx",
        function()
          require("notebook-navigator").run_and_move()
        end,
        desc = "Run cell + move (NotebookNavigator)",
      },
      {
        "<leader>ja",
        function()
          require("notebook-navigator").run_all_cells()
        end,
        desc = "Run all cells (NotebookNavigator)",
      },
      {
        "<leader>jb",
        function()
          require("notebook-navigator").run_cells_below()
        end,
        desc = "Run cells below (NotebookNavigator)",
      },
      {
        "<leader>j>",
        function()
          require("notebook-navigator").swap_cell("d")
        end,
        desc = "Swap cell down (NotebookNavigator)",
      },
      {
        "<leader>j<",
        function()
          require("notebook-navigator").swap_cell("u")
        end,
        desc = "Swap cell up (NotebookNavigator)",
      },
      {
        "<leader>jn",
        function()
          require("notebook-navigator").add_cell_below()
        end,
        desc = "Add cell below (NotebookNavigator)",
      },
      {
        "<leader>jN",
        function()
          require("notebook-navigator").add_cell_above()
        end,
        desc = "Add cell above (NotebookNavigator)",
      },
      {
        "<leader>jm",
        function()
          require("notebook-navigator").merge_cell("d")
        end,
        desc = "Merge cell below (NotebookNavigator)",
      },
      {
        "<leader>jM",
        function()
          require("notebook-navigator").merge_cell("u")
        end,
        desc = "Merge cell above (NotebookNavigator)",
      },
      {
        "<leader>jC",
        function()
          require("notebook-navigator").comment_cell()
        end,
        desc = "Comment cell (NotebookNavigator)",
      },
      {
        "<leader>j-",
        function()
          require("notebook-navigator").split_cell()
        end,
        desc = "Split cell (NotebookNavigator)",
      },
    },
  },
  -- Ensure which-key shows a Jupyter group for <leader>j
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<leader>j", group = "Jupyter", icon = "󰠮" },
        })
      end
      return opts
    end,
  },
}
