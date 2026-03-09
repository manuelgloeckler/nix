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
      -- Display: use persistent inline virtual text per cell (notebook-like).
      -- Disable output_virt_lines (float-window padding) — it fights with
      -- virt_text_output and causes messy layout on batch runs.
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_image_location = "virt"

      vim.g.molten_virt_text_output = true
      vim.g.molten_output_virt_lines = false
      vim.g.molten_auto_open_output = false

      vim.g.molten_cover_empty_lines = true
      vim.g.molten_wrap_output = true

      vim.g.molten_tick_rate = 150
      vim.g.molten_virt_text_max_lines = 20
      vim.g.molten_limit_output_chars = 20000

      vim.g.molten_output_win_max_height = 20
      vim.g.molten_output_win_style = "minimal"
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
      vim.keymap.set("n", "<leader>jD", function()
        -- Clear all molten outputs in the buffer
        pcall(vim.cmd, "MoltenDelete!")
      end, { desc = "Molten: clear all outputs" })
      vim.keymap.set("n", "<leader>jA", function()
        -- Restart kernel then run all cells
        pcall(vim.cmd, "MoltenRestart!")
        vim.defer_fn(function()
          local ok, nn = pcall(require, "notebook-navigator")
          if ok then nn.run_all_cells() end
        end, 300)
      end, { desc = "Molten: restart kernel + run all" })
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
      cells = { "jupytext" },
      repl_provider = "molten",
      syntax_highlight = true,
      show_hydra_hint = false, -- safer default if hydra keys are remapped
    },
    config = function(_, opts)
      local nn = require("notebook-navigator")
      nn.setup(opts)

      -- Fix: run_all_cells / run_cells_below must evaluate each cell individually.
      -- The default impl sends the entire range to molten as one giant cell,
      -- so outputs all pile up at the end instead of attaching per-cell.
      local ok_utils, utils = pcall(require, "notebook-navigator.utils")
      local ok_miniai, miniai_mod = pcall(require, "notebook-navigator.miniai_spec")
      if not (ok_utils and ok_miniai) then
        vim.notify("NotebookNavigator internals unavailable, cell overrides skipped", vim.log.levels.WARN)
        return
      end
      local miniai_spec = miniai_mod.miniai_spec

      local function cell_marker()
        return utils.get_cell_marker(0, nn.config.cell_markers)
      end

      --- Return list of {start_line, end_line} for each cell (1-indexed, inclusive).
      --- @param from_line number? first line to include (default 1)
      local function get_cell_ranges(from_line)
        local last = vim.api.nvim_buf_line_count(0)
        local lines = vim.api.nvim_buf_get_lines(0, 0, last, false)
        local marker = cell_marker()
        local pat = "^" .. vim.pesc(marker)

        -- Collect cell start lines (line *after* the marker)
        local starts = { 1 }
        for i, line in ipairs(lines) do
          if line:find(pat) then
            starts[#starts + 1] = i + 1
          end
        end

        local ranges = {}
        local lower = from_line or 1

        for idx, s in ipairs(starts) do
          local e = (idx < #starts) and (starts[idx + 1] - 2) or last
          s = math.max(s, lower)
          if s <= e then
            -- Skip cells that are entirely blank
            local chunk = table.concat(vim.api.nvim_buf_get_lines(0, s - 1, e, false), "\n")
            if chunk:find("%S") then
              ranges[#ranges + 1] = { s, e }
            end
          end
        end

        return ranges
      end

      local function ensure_molten()
        local ok_status, molten_status = pcall(require, "molten.status")
        if ok_status and molten_status.initialized() == "" then
          local ok = pcall(vim.cmd, "MoltenInit")
          if not ok then
            vim.notify("MoltenInit failed", vim.log.levels.ERROR)
            return false
          end
        elseif not ok_status then
          -- molten.status unavailable, try initializing anyway
          pcall(vim.cmd, "MoltenInit")
        end
        return true
      end

      local function run_ranges(ranges)
        if not ensure_molten() then return end
        local marker = cell_marker()
        for _, r in ipairs(ranges) do
          -- The molten adapter appends a marker line if the buffer is too short,
          -- so replicate that guard here.
          local buf_len = vim.api.nvim_buf_line_count(0)
          if buf_len < (r[2] + 1) then
            vim.api.nvim_buf_set_lines(0, r[2] + 1, r[2] + 1, false, { marker, "" })
          end
          vim.fn.MoltenEvaluateRange(r[1], r[2] + 1)
        end
      end

      nn.run_all_cells = function()
        run_ranges(get_cell_ranges(1))
      end

      nn.run_cells_below = function()
        local cur = miniai_spec("i", cell_marker())
        run_ranges(get_cell_ranges(cur.from.line))
      end

      -- VS Code-style Shift+Enter / Ctrl+Enter for notebook buffers.
      -- <S-CR> only works if your terminal sends a distinct keycode;
      -- test with: insert mode -> Ctrl-V -> Shift-Enter.
      local function run_and_move_any_mode()
        local mode = vim.api.nvim_get_mode().mode
        if mode:sub(1, 1) == "i" then
          vim.cmd("stopinsert")
          vim.schedule(function() nn.run_and_move() end)
        else
          nn.run_and_move()
        end
      end

      local group = vim.api.nvim_create_augroup("NotebookShiftEnter", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "python", "ipynb" },
        callback = function(args)
          local buf = args.buf
          vim.keymap.set("n", "<S-CR>", run_and_move_any_mode, {
            buffer = buf, silent = true, desc = "Run cell and jump to next",
          })
          vim.keymap.set("i", "<S-CR>", run_and_move_any_mode, {
            buffer = buf, silent = true, desc = "Run cell and jump to next",
          })
          vim.keymap.set("n", "<C-CR>", function() nn.run_cell() end, {
            buffer = buf, silent = true, desc = "Run current cell",
          })
        end,
      })
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
