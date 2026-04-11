return {
  -- remote-nvim.nvim: edit code on remote machines over SSH.
  --
  -- Designed to work on remotes that:
  --   * don't have neovim installed  -> the plugin ships neovim_install.sh
  --     which downloads a prebuilt neovim tarball into the user's $HOME
  --     (no sudo, no system package manager).
  --   * don't have root / package manager access -> everything lives under
  --     ~/.remote-nvim/ on the remote, owned by the remote user.
  --   * don't have node/npm/etc. -> the plugin itself only needs `bash`,
  --     `curl` (or `wget`) and `tar` on the remote. Mason LSPs that need
  --     npm/pip/etc. are a separate concern and may simply fail to install
  --     on such remotes — that's fine, core editing still works.
  --
  -- Usage:
  --   :RemoteStart    -- pick/launch a remote (ssh host, docker, devcontainer)
  --   :RemoteStop     -- stop the session
  --   :RemoteInfo     -- show session info
  --   :RemoteCleanup  -- clean up a remote's installation
  --   :checkhealth remote-nvim
  {
    "amitds1997/remote-nvim.nvim",
    version = "*",
    cmd = {
      "RemoteStart",
      "RemoteStop",
      "RemoteInfo",
      "RemoteCleanup",
      "RemoteConfigDel",
      "RemoteLog",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      -- Where the plugin stores its own state locally.
      -- (defaults are fine, listed here for discoverability)
      client_callback = function(port, workspace_config)
        -- default: open a new kitty/wezterm/tmux pane and ssh into the
        -- remote port. Leaving the default behavior in place.
        local cmd = ("nvim --server localhost:%s --remote-ui"):format(port)
        vim.fn.jobstart(cmd, { detach = true })
      end,

      -- SSH: rely on the user's ~/.ssh/config for hosts, jumps, keys, etc.
      ssh_config = {
        ssh_binary = "ssh",
        scp_binary = "scp",
        ssh_config_file_paths = { "$HOME/.ssh/config" },
      },

      -- Remote install: put everything under the remote user's $HOME, no
      -- sudo, no system packages. The plugin's neovim_install.sh downloads
      -- a prebuilt neovim tarball into ~/.remote-nvim on the remote.
      remote = {
        app_name = "nvim", -- NVIM_APPNAME on the remote
        copy_dirs = {
          -- Mirror the full local nvim config to the remote.
          config = {
            base = vim.fn.stdpath("config"),
            dirs = "*",
            compression = { enabled = true, additional_opts = { "--exclude=lazy-lock.json" } },
          },
          -- Don't bother syncing local plugin data / state — remote will
          -- bootstrap its own via lazy.nvim on first launch.
          data = { base = vim.fn.stdpath("data"), dirs = {} },
          cache = { base = vim.fn.stdpath("cache"), dirs = {} },
          state = { base = vim.fn.stdpath("state"), dirs = {} },
        },
      },

      -- Offline mode: flip `enabled = true` on machines with no internet;
      -- the plugin will then serve neovim tarballs from `cache_dir` instead
      -- of fetching from GitHub. Pre-populate that dir with the release
      -- tarballs you need if you plan to go fully offline.
      offline_mode = {
        enabled = false,
        no_github = false,
        cache_dir = vim.fn.stdpath("cache") .. "/remote-nvim/version_cache",
      },

      -- Devpod / devcontainer support is optional; only used if `:RemoteStart`
      -- is launched against a devcontainer workspace.
      devpod = {
        binary = "devpod",
        docker_binary = "docker",
      },
    },
    keys = {
      { "<leader>rS", "<cmd>RemoteStart<cr>",   desc = "Remote: start session" },
      { "<leader>rx", "<cmd>RemoteStop<cr>",    desc = "Remote: stop session" },
      { "<leader>ri", "<cmd>RemoteInfo<cr>",    desc = "Remote: session info" },
      { "<leader>rl", "<cmd>RemoteLog<cr>",     desc = "Remote: open log" },
      { "<leader>rc", "<cmd>RemoteCleanup<cr>", desc = "Remote: cleanup host" },
    },
  },

  -- which-key group label for the remote prefix
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, _)
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({ { "<leader>r", group = "Remote" } })
      end
    end,
  },
}
