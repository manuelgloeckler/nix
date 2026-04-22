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
  --   :RemoteStart           -- pick/launch a remote (ssh host, docker, devcontainer)
  --   :RemoteStop            -- stop the session
  --   :RemoteInfo            -- show session info
  --   :RemoteCleanup         -- clean up a remote's installation
  --   :RemoteOpencodeSync    -- install opencode (if missing) + copy auth.json
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
      -- Shared helper used by both the client_callback (auto-sync on session
      -- start) and the :RemoteOpencodeSync user command (manual re-sync).
      --
      -- Installs opencode on the remote if missing (via the upstream installer)
      -- and scp's the local auth.json over. Fully async (jobstart), so the
      -- UI start in client_callback doesn't block on it.
      local function ensure_opencode_on_remote(host, conn_opts, on_done)
        on_done = on_done or function() end
        conn_opts = conn_opts or ""

        local auth_path = vim.fn.expand("~/.local/share/opencode/auth.json")
        if vim.fn.filereadable(auth_path) == 0 then
          vim.notify("[opencode-sync] local auth.json not found at " .. auth_path
            .. " — skipping", vim.log.levels.WARN)
          return on_done(false)
        end

        local ssh_bin = (require("remote-nvim").config.ssh_config or {}).ssh_binary or "ssh"
        local scp_bin = (require("remote-nvim").config.ssh_config or {}).scp_binary or "scp"

        local remote_script = table.concat({
          "set -e",
          "mkdir -p \"$HOME/.local/share/opencode\"",
          "if ! command -v opencode >/dev/null 2>&1 && [ ! -x \"$HOME/.opencode/bin/opencode\" ]; then",
          "  echo '[opencode-sync] installing opencode on remote via upstream script...'",
          "  curl -fsSL https://opencode.ai/install | bash",
          "else",
          "  echo '[opencode-sync] opencode already present on remote.'",
          "fi",
        }, "; ")

        local function build_cmd(bin, extra_flags)
          local cmd = { bin }
          for _, f in ipairs(extra_flags or {}) do table.insert(cmd, f) end
          if conn_opts ~= "" then
            for token in conn_opts:gmatch("%S+") do table.insert(cmd, token) end
          end
          return cmd
        end

        local function pump(data, level)
          if not data then return end
          for _, line in ipairs(data) do
            if line ~= "" then
              vim.schedule(function()
                vim.notify(line, level, { title = "opencode-sync" })
              end)
            end
          end
        end

        local ssh_cmd = build_cmd(ssh_bin, {})
        table.insert(ssh_cmd, host)
        table.insert(ssh_cmd, remote_script)

        vim.fn.jobstart(ssh_cmd, {
          stdout_buffered = true,
          stderr_buffered = true,
          on_stdout = function(_, d) pump(d, vim.log.levels.INFO) end,
          on_stderr = function(_, d) pump(d, vim.log.levels.WARN) end,
          on_exit = function(_, prep_code)
            if prep_code ~= 0 then
              vim.schedule(function()
                vim.notify(("[opencode-sync] remote prep failed (exit %d) on %s"):format(prep_code, host),
                  vim.log.levels.ERROR)
              end)
              return on_done(false)
            end
            -- Upload auth.json (use -p to keep 0600 perms).
            local scp_cmd = build_cmd(scp_bin, { "-p" })
            table.insert(scp_cmd, auth_path)
            table.insert(scp_cmd, host .. ":.local/share/opencode/auth.json")
            vim.fn.jobstart(scp_cmd, {
              stdout_buffered = true,
              stderr_buffered = true,
              on_stdout = function(_, d) pump(d, vim.log.levels.INFO) end,
              on_stderr = function(_, d) pump(d, vim.log.levels.WARN) end,
              on_exit = function(_, scp_code)
                vim.schedule(function()
                  if scp_code == 0 then
                    vim.notify(("[opencode-sync] auth.json synced to %s"):format(host), vim.log.levels.INFO)
                  else
                    vim.notify(("[opencode-sync] scp failed (exit %d) for %s"):format(scp_code, host),
                      vim.log.levels.ERROR)
                  end
                end)
                on_done(scp_code == 0)
              end,
            })
          end,
        })
      end
      -- Expose for the config() phase so :RemoteOpencodeSync can reuse it.
      _G.__remote_opencode_sync = ensure_opencode_on_remote

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
        client_callback = function(port, workspace_config)
          -- Auto-sync opencode on remote as part of session startup. Runs in
          -- parallel with the UI client: opencode install / auth upload is
          -- background work and must not block the editor coming up.
          if workspace_config and workspace_config.host then
            ensure_opencode_on_remote(workspace_config.host, workspace_config.connection_options or "")
          end

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
                  -- opencode.lua is intentionally NOT excluded: the opencode
                  -- CLI is installed on the remote either by the flake's
                  -- linuxServerHomeModule (nix package) or by :RemoteOpencodeSync
                  -- (curl-based installer + auth.json upload) below.
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
    config = function(_, opts)
      -- Standard setup passthrough for the plugin.
      require("remote-nvim").setup(opts)

      -- :RemoteOpencodeSync [host]
      --   Ensures opencode CLI is available on a remote and copies the local
      --   auth.json (~/.local/share/opencode/auth.json) over so the remote
      --   can talk to the same providers as the local workstation.
      --
      --   How host is picked:
      --     1) Explicit arg:  :RemoteOpencodeSync user@host
      --     2) Otherwise, the unique active remote-nvim SSH session (if exactly 1)
      --     3) Otherwise, errors listing active session ids — pick one explicitly
      --
      --   Install path: if `opencode` is not on the remote's PATH, we run
      --   `curl -fsSL https://opencode.ai/install | bash` (the upstream
      --   install script). On hosts managed by this flake's linuxServerHomeModule
      --   opencode is already provided via nix and this is a no-op.
      local function pick_ssh_target(explicit)
        if explicit and explicit ~= "" then
          return explicit, ""
        end
        local ok, rn = pcall(require, "remote-nvim")
        if not ok or not rn.session_provider then
          return nil, nil, "remote-nvim session provider unavailable"
        end
        local sessions = rn.session_provider:get_all_sessions() or {}
        local ssh_sessions = {}
        for id, session in pairs(sessions) do
          -- Filter to ssh-like providers (have `host` + `conn_opts`).
          if session and session.host then
            table.insert(ssh_sessions, { id = id, host = session.host, conn_opts = session.conn_opts or "" })
          end
        end
        if #ssh_sessions == 0 then
          return nil, nil, "no active remote-nvim SSH sessions; pass a host explicitly"
        elseif #ssh_sessions == 1 then
          return ssh_sessions[1].host, ssh_sessions[1].conn_opts
        else
          -- Multiple sessions; let caller disambiguate via arg.
          local ids = {}
          for _, s in ipairs(ssh_sessions) do table.insert(ids, s.id) end
          return nil, nil, "multiple active sessions (" .. table.concat(ids, ", ") .. "); pass a host explicitly"
        end
      end

      vim.api.nvim_create_user_command("RemoteOpencodeSync", function(cmd_opts)
        local host, conn_opts, err = pick_ssh_target(cmd_opts.args)
        if not host then
          vim.notify("RemoteOpencodeSync: " .. (err or "no host"), vim.log.levels.ERROR)
          return
        end
        if type(_G.__remote_opencode_sync) ~= "function" then
          vim.notify("RemoteOpencodeSync: helper not initialised (plugin opts() didn't run)",
            vim.log.levels.ERROR)
          return
        end
        vim.notify(("RemoteOpencodeSync: preparing %s"):format(host), vim.log.levels.INFO)
        _G.__remote_opencode_sync(host, conn_opts or "")
      end, {
        nargs = "?",
        desc = "Remote: install opencode (if missing) and copy auth.json to the remote",
        complete = function()
          local ok, rn = pcall(require, "remote-nvim")
          if not ok or not rn.session_provider then return {} end
          local out, sessions = {}, rn.session_provider:get_all_sessions() or {}
          for _, s in pairs(sessions) do
            if s and s.host then table.insert(out, s.host) end
          end
          return out
        end,
      })
    end,
    keys = {
      { "<leader>rS", "<cmd>RemoteStart<cr>",        desc = "Remote: start session" },
      { "<leader>rx", "<cmd>RemoteStop<cr>",         desc = "Remote: stop session" },
      { "<leader>ri", "<cmd>RemoteInfo<cr>",         desc = "Remote: session info" },
      { "<leader>rl", "<cmd>RemoteLog<cr>",          desc = "Remote: open log" },
      { "<leader>rc", "<cmd>RemoteCleanup<cr>",      desc = "Remote: cleanup host" },
      { "<leader>ro", "<cmd>RemoteOpencodeSync<cr>", desc = "Remote: sync opencode auth + install" },
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
