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
      -- Disable swap files for .ipynb buffers BEFORE jupytext's BufReadCmd fires.
      -- Without this, nvim_buf_set_lines inside BufReadCmd can trigger E325
      -- (swap file ATTENTION) which cannot be answered interactively in a
      -- callback, causing the notebook open to fail.
      vim.api.nvim_create_autocmd("BufNew", {
        pattern = "*.ipynb",
        callback = function(ev)
          vim.bo[ev.buf].swapfile = false
        end,
      })

      -- Patch jupytext to handle empty/new .ipynb files.
      -- jupytext.nvim crashes when opening an empty .ipynb because
      -- vim.json.decode("") fails. We seed the file with minimal
      -- valid notebook JSON before the decode happens.
      local utils = require("jupytext.utils")
      local orig_get_metadata = utils.get_ipynb_metadata
      utils.get_ipynb_metadata = function(filename)
        local stat = (vim.uv or vim.loop).fs_stat(filename)
        if not stat or stat.size == 0 then
          local minimal = vim.json.encode({
            cells = {},
            metadata = {
              kernelspec = {
                display_name = "Python 3",
                language = "python",
                name = "python3",
              },
              language_info = { name = "python" },
            },
            nbformat = 4,
            nbformat_minor = 5,
          })
          local f = io.open(filename, "w")
          if f then
            f:write(minimal)
            f:close()
          end
        end
        return orig_get_metadata(filename)
      end

      require("jupytext").setup(opts)

      -- ── Manifest-based orphan cleanup for jupytext temp files ──────────
      -- jupytext.nvim creates a companion .py file when opening .ipynb.
      -- It cleans up via BufUnload, but that won't fire on crashes,
      -- terminal kills, or force-quit. We track created temp files in a
      -- JSON manifest and sweep orphans on the next Neovim startup.

      local manifest_path = vim.fn.stdpath("cache") .. "/jupytext-tempfiles.json"
      local fs = vim.uv or vim.loop

      local function manifest_read()
        local stat = fs.fs_stat(manifest_path)
        if not stat or stat.size == 0 then
          return {}
        end
        local f = io.open(manifest_path, "r")
        if not f then
          return {}
        end
        local raw = f:read("*a")
        f:close()
        local ok, data = pcall(vim.json.decode, raw)
        if ok and type(data) == "table" then
          return data
        end
        return {}
      end

      local function manifest_write(entries)
        local f = io.open(manifest_path, "w")
        if not f then
          return
        end
        f:write(vim.json.encode(entries))
        f:close()
      end

      local function manifest_add(filepath)
        local entries = manifest_read()
        for _, v in ipairs(entries) do
          if v == filepath then
            return -- already tracked
          end
        end
        entries[#entries + 1] = filepath
        manifest_write(entries)
      end

      local function manifest_remove(filepath)
        local entries = manifest_read()
        local filtered = {}
        for _, v in ipairs(entries) do
          if v ~= filepath then
            filtered[#filtered + 1] = v
          end
        end
        manifest_write(filtered)
      end

      -- Sweep orphaned temp files from previous sessions on startup.
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          local entries = manifest_read()
          if #entries == 0 then
            return
          end
          local remaining = {}
          for _, filepath in ipairs(entries) do
            if fs.fs_stat(filepath) then
              local ok = pcall(os.remove, filepath)
              if not ok then
                -- couldn't delete, keep tracking it
                remaining[#remaining + 1] = filepath
              end
            end
            -- file already gone — don't re-add to manifest
          end
          manifest_write(remaining)
        end,
        once = true,
      })

      -- After jupytext opens a notebook and creates the companion file,
      -- record it in the manifest. We use BufReadPost *.ipynb because
      -- jupytext's BufReadCmd fires first and creates the companion.
      -- We also set up a BufUnload hook to remove the manifest entry
      -- when the normal cleanup path succeeds.
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.ipynb",
        callback = function(ev)
          local ipynb = vim.fn.resolve(vim.fn.expand(ev.match))
          if vim.fn.filereadable(ipynb) ~= 1 then
            return
          end
          -- Compute the companion path the same way jupytext.nvim does
          local ok_meta, metadata = pcall(utils.get_ipynb_metadata, ipynb)
          if not ok_meta or not metadata or not metadata.extension then
            return
          end
          local companion = utils.get_jupytext_file(ipynb, metadata.extension)
          companion = vim.fn.resolve(vim.fn.expand(companion))
          -- Only track if jupytext actually created it (it exists on disk)
          if not fs.fs_stat(companion) then
            return
          end
          manifest_add(companion)

          -- On BufUnload, if jupytext's cleanup deleted the file, remove
          -- it from the manifest. If it's still there (pre-existing paired
          -- file), also remove from manifest since we shouldn't touch it.
          vim.api.nvim_create_autocmd("BufUnload", {
            buffer = ev.buf,
            once = true,
            callback = function()
              manifest_remove(companion)
            end,
          })
        end,
      })
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
    opts = function(_, opts)
      -- Prefer the fast native magick Lua binding; fall back to CLI if unavailable
      local use_rock = pcall(require, "magick")
      return vim.tbl_deep_extend("force", opts or {}, {
        backend = "kitty",
        rocks = { "magick" },
        processor = use_rock and "magick_rock" or "magick_cli",
        integrations = {
          markdown = { enabled = true },
          neorg = { enabled = true },
          html = { enabled = true },
          css = { enabled = true },
        },
        max_width = 300,
        max_height = 300,
        max_height_window_percentage = math.huge,
        max_width_window_percentage = math.huge,
        window_overlap_clear_enabled = true,
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      })
    end,
    config = function(_, opts)
      -- If falling back to magick_cli, increase the 10s timeout to 30s so
      -- slow CLI spawns on Nix-darwin don't immediately error out.
      if opts.processor == "magick_cli" then
        local cli = require("image.processors.magick_cli")
        local orig_resize = cli.resize
        cli.resize = function(path, width, height, output_path)
          local uv = vim.uv or vim.loop
          local out_path = output_path or path:gsub("%.([^.]+)$", "-resized.%1")
          local done = false
          local stdout = uv.new_pipe()
          local stderr = uv.new_pipe()
          local error_output = ""
          local convert_cmd = vim.fn.executable("magick") == 1 and "magick" or "convert"
          uv.spawn(convert_cmd, {
            args = { path, "-scale", string.format("%dx%d", width, height), out_path },
            stdio = { nil, stdout, stderr },
            hide = true,
          }, function(code)
            if code ~= 0 then
              error(error_output ~= "" and error_output or "Failed to resize")
            end
            done = true
          end)
          uv.read_start(stderr, function(err, data)
            assert(not err, err)
            if data then error_output = error_output .. data end
          end)
          local success = vim.wait(30000, function() return done end, 10)
          if not success then error("operation timed out (30s)") end
          return out_path
        end
      end

      require("image").setup(opts)

      -- image.nvim fires magick CLI calls on every WinScrolled event with no
      -- debounce — fast scrolling creates dozens of concurrent resize processes
      -- that all time out.  We delete the plugin's autocmd group and re-create
      -- its handlers with a 150 ms debounce on the scroll path.

      -- Delete image.nvim's built-in autocmd group (setup() already ran).
      pcall(vim.api.nvim_del_augroup_by_name, "image.nvim")

      local image = require("image")

      -- --- helper: our own augroup for the replacement handlers -------------
      local grp = vim.api.nvim_create_augroup("image.nvim", { clear = true })

      -- --- 1) Clear on buffer / window change (BufLeave, WinClosed, TabEnter)
      vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed", "TabEnter" }, {
        group = grp,
        callback = function()
          if not image.is_enabled() then return end
          vim.schedule(function()
            local images = image.get_images()
            local tab_wins = vim.api.nvim_tabpage_list_wins(0)
            local tab_win_map = {}
            for _, w in ipairs(tab_wins) do tab_win_map[w] = true end

            for _, img in ipairs(images) do
              if img.window then
                local ok, valid = pcall(vim.api.nvim_win_is_valid, img.window)
                if not ok or not valid then
                  img:clear()
                elseif not tab_win_map[img.window] then
                  img:clear()
                elseif img.buffer then
                  local b_ok, b_valid = pcall(vim.api.nvim_buf_is_valid, img.buffer)
                  if not b_ok or not b_valid then
                    img:clear()
                  elseif vim.api.nvim_win_get_buf(img.window) ~= img.buffer then
                    img:clear()
                  end
                end
              end
            end
          end)
        end,
      })

      -- --- 2) WinScrolled → DEBOUNCED re-render -----------------------------
      -- Re-query images inside the timer callback so we never work with a
      -- stale list captured before the debounce window.
      local scroll_timer = vim.uv.new_timer()
      vim.api.nvim_create_autocmd("WinScrolled", {
        group = grp,
        callback = function(au)
          if not image.is_enabled() then return end
          local winid = tonumber(au.file)
          if not winid or not vim.api.nvim_win_is_valid(winid) then return end
          scroll_timer:stop()
          scroll_timer:start(200, 0, vim.schedule_wrap(function()
            if not vim.api.nvim_win_is_valid(winid) then return end
            local images = image.get_images({ window = winid })
            for _, img in ipairs(images) do
              local buf_ok, buf_valid = pcall(vim.api.nvim_buf_is_valid, img.buffer)
              if buf_ok and buf_valid and vim.api.nvim_win_get_buf(winid) == img.buffer then
                pcall(img.render, img)
              end
            end
          end))
        end,
      })

      -- --- 3) WinResized / WinNew → DEBOUNCED clear + re-render -------------
      local resize_timer = vim.uv.new_timer()
      vim.api.nvim_create_autocmd({ "WinResized", "WinNew" }, {
        group = grp,
        callback = function()
          if not image.is_enabled() then return end
          resize_timer:stop()
          resize_timer:start(200, 0, vim.schedule_wrap(function()
            local images = image.get_images()
            for _, img in ipairs(images) do
              if img.window and vim.api.nvim_win_is_valid(img.window) then
                local buf_ok, buf_valid = pcall(vim.api.nvim_buf_is_valid, img.buffer)
                if buf_ok and buf_valid and vim.api.nvim_win_get_buf(img.window) == img.buffer then
                  pcall(img.clear, img)
                  pcall(img.render, img)
                end
              end
            end
          end))
        end,
      })

      -- --- 4) Clear images when closing a notebook buffer -------------------
      -- Prevents errors when molten temp PNGs are deleted and image.nvim tries
      -- to re-render them on the next WinScrolled / WinResized.
      vim.api.nvim_create_autocmd("BufUnload", {
        group = vim.api.nvim_create_augroup("image_clear_on_unload", { clear = true }),
        callback = function(ev)
          pcall(function()
            local instances = image.get_images({ buffer = ev.buf })
            for _, img in ipairs(instances) do
              img:clear()
            end
          end)
        end,
      })
    end,
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
