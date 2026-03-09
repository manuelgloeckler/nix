return {
  {
    "nickjvandyke/opencode.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>ao",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle OpenCode",
        mode = "n",
      },
      {
        "<leader>aa",
        function()
          require("opencode").ask("@this: ", { submit = true })
        end,
        desc = "Ask OpenCode",
        mode = { "n", "x" },
      },
      {
        "<leader>as",
        function()
          require("opencode").select()
        end,
        desc = "OpenCode Actions",
        mode = { "n", "x" },
      },
      {
        "<leader>af",
        function()
          require("opencode").prompt("explain @buffer")
        end,
        desc = "OpenCode Explain File",
        mode = "n",
      },
      {
        "<leader>av",
        function()
          require("opencode").prompt("review @this")
        end,
        desc = "OpenCode Review Selection",
        mode = "x",
      },
      {
        "<leader>ai",
        function()
          require("opencode").command("session.interrupt")
        end,
        desc = "OpenCode Interrupt",
        mode = { "n", "t" },
      },
      {
        "<D-M-C-o>",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle OpenCode (Super+o)",
        mode = { "n", "t" },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          anti_conceal = { enabled = false },
          file_types = { "markdown", "opencode_output" },
        },
        ft = { "markdown", "Avante", "opencode_output" },
      },
      "saghen/blink.cmp",
    },
    init = function()
      vim.o.autoread = true
      local opencode_cmd = "opencode --port"
      local snacks_opts = {
        win = {
          position = "float",
          width = 0.88,
          height = 0.82,
          border = "rounded",
          on_win = function(win)
            local winid = win and win.win
            if not winid or not vim.api.nvim_win_is_valid(winid) then
              return
            end

            local buf = vim.api.nvim_win_get_buf(winid)
            if vim.b[buf].opencode_terminal_setup_done then
              return
            end

            vim.b[buf].opencode_terminal_setup_done = true
            require("opencode.terminal").setup(winid)
          end,
        },
      }
      vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, {
        keymap_prefix = "<leader>a",
        server = {
          start = function()
            require("snacks.terminal").open(opencode_cmd, snacks_opts)
          end,
          stop = function()
            require("snacks.terminal").get(opencode_cmd, snacks_opts):close()
          end,
          toggle = function()
            require("snacks.terminal").toggle(opencode_cmd, snacks_opts)
          end,
        },
      })
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("opencode_terminal_input_mode", { clear = true })
      vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
        group = group,
        pattern = { "term://*", "*" },
        callback = function(args)
          local name = vim.api.nvim_buf_get_name(args.buf)
          local ft = vim.bo[args.buf].filetype
          local bt = vim.bo[args.buf].buftype
          local is_opencode_term = name:find("opencode", 1, true)
            or ft == "opencode_terminal"
            or (ft == "snacks_terminal" and name:find("opencode", 1, true))

          if not is_opencode_term or bt ~= "terminal" then
            return
          end

          local to_terminal_mode = function()
            vim.cmd("startinsert")
          end
          vim.keymap.set("n", "i", to_terminal_mode, { buffer = args.buf, desc = "OpenCode: Enter input mode" })
          vim.keymap.set("n", "a", to_terminal_mode, { buffer = args.buf, desc = "OpenCode: Enter input mode" })
          vim.keymap.set("n", "I", to_terminal_mode, { buffer = args.buf, desc = "OpenCode: Enter input mode" })
          vim.keymap.set("n", "A", to_terminal_mode, { buffer = args.buf, desc = "OpenCode: Enter input mode" })
        end,
      })
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, wk = pcall(require, "which-key")
      if not ok then
        return opts
      end
      wk.add({
        { "<leader>a", group = "AI" },
      })
      return opts
    end,
  },
}
