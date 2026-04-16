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
    opts = function()
      -- Nix / home-manager note:
      --   `~/.config/nvim` is a symlink into /nix/store and the contents are
      --   mode r-xr-xr-x (dirs) / r--r--r-- (files), owned by root:nixbld.
      --   remote-nvim's uploader does `tar czf -` over those paths, which
      --   embeds the read-only mode bits into the archive. On the remote,
      --   `tar xvzf` then recreates `./lua` as r-x, and every subsequent
      --   `mkdir ./lua/config` / `./lua/plugins` fails with EACCES, followed
      --   by cascading "No such file or directory" errors for every child.
      --
      --   Fix: tar from the *writable* dotfile source under the nix flake
      --   (owned by the user, normal 755/644 modes) instead of the nix-store
      --   symlink. Same content either way since home-manager links from it.
      local dotfiles_nvim = vim.fn.expand("~/.config/nix/dotfiles/nvim")
      local install_script = dotfiles_nvim .. "/remote-nvim-install.sh"
      local config_base = (vim.fn.isdirectory(dotfiles_nvim) == 1) and dotfiles_nvim
        or vim.fn.stdpath("config")

      return {
        neovim_install_script_path = install_script,
        client_callback = function(port, _)
          -- `--remote-ui` needs a real terminal. A detached job starts no UI,
          -- which makes the session look stuck after the server comes up.
          require("remote-nvim.ui").float_term(("nvim --server localhost:%s --remote-ui"):format(port), function(exit_code)
            if exit_code ~= 0 then
              vim.notify(("Local client failed with exit code %s"):format(exit_code), vim.log.levels.ERROR)
            end
          end)
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
              base = config_base,
              dirs = "*",
              compression = {
                enabled = true,
                -- Exclude plugin spec files that pull in tooling the remote
                -- probably doesn't have (luarocks, node, python+jupyter, DAP
                -- adapters, external AI CLIs). Leaving them in causes lazy.nvim
                -- to fail resolving deps ("Too many rounds of missing plugins").
                --
                -- Also exclude remote.lua itself — we don't want a remote-nvim
                -- session launching another remote-nvim session.
                additional_opts = {
                  "--exclude=./lazy-lock.json",
                  "--exclude=./.git",
                  "--exclude=./LICENSE",
                  "--exclude=./README.md",
                  "--exclude=./lua/plugins/jupyter.lua",  -- image.nvim + magick rock, molten, jupytext venv
                  "--exclude=./lua/plugins/copilot.lua",  -- needs node
                  "--exclude=./lua/plugins/codex.lua",    -- external AI CLI
                  "--exclude=./lua/plugins/opencode.lua", -- external AI CLI
                  "--exclude=./lua/plugins/debug.lua",    -- DAP adapters
                  "--exclude=./lua/plugins/neotest-python.lua", -- pytest / venv
                  "--exclude=./lua/plugins/leetcode.lua", -- external leetcode tool
                  "--exclude=./lua/plugins/remote.lua",   -- no remote-in-remote
                },
              },
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
      }
    end,
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
