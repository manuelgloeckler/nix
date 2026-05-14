-- Require Neovim >= 0.11.2 for latest LazyVim
do
  local v = vim.version and vim.version() or { major = 0, minor = 0, patch = 0 }
  local ok = (v.major > 0) or (v.major == 0 and (v.minor > 11 or (v.minor == 11 and v.patch >= 2)))
  if not ok then
    vim.schedule(function()
      vim.notify(
        string.format("LazyVim now requires Neovim >= 0.11.2 (found %d.%d.%d)", v.major, v.minor, v.patch),
        vim.log.levels.ERROR
      )
    end)
  end
end

-- Detect remote-nvim.nvim headless host *before* lazy.nvim starts, so plugin
-- specs / extras can gate themselves with `cond = not vim.g.remote_neovim_host`.
-- remote-nvim.nvim sets this same flag later via --remote-send, which is too
-- late for lazy.nvim's dep resolution. We detect it early via the XDG workspace
-- path the plugin injects into the remote's environment.
if (vim.env.XDG_CONFIG_HOME or ""):find("%.remote%-nvim/workspaces", 1) then
  vim.g.remote_neovim_host = true
end

if vim.g.remote_neovim_host then
  local xdg_config_home = vim.env.XDG_CONFIG_HOME or ""
  local remote_nvim_home = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(xdg_config_home)))
  if remote_nvim_home and remote_nvim_home ~= "." then
    local remote_bin = remote_nvim_home .. "/bin"
    if vim.fn.isdirectory(remote_bin) == 1 then
      local path = vim.env.PATH or ""
      vim.env.PATH = remote_bin .. (path ~= "" and (":" .. path) or "")
    end
  end
end

-- Configure Python provider venv early so plugin builds use it.
-- Skip on a remote-nvim host — there's typically no local Python toolchain
-- and the venv bootstrap will just spin.
if not vim.g.remote_neovim_host then
  pcall(function()
    local py = require("config.python")
    py.configure_provider()
  end)
end

-- ImageMagick: help the magick Lua rock find MagickWand on Nix-darwin.
-- luarocks' magick module uses pkg-config at build time and ffi.load at
-- runtime; neither works out-of-the-box because Nix doesn't place .pc files
-- or dylibs on standard search paths.
-- Skip on remote-nvim hosts — image.nvim/molten aren't shipped there.
--
-- IM 7.x removed `magick --prefix`, so we resolve the runtime prefix by
-- following the symlink chain from the binary instead. The .pc files live
-- in a separate `imagemagick-*-dev` Nix output (declared in flake.nix);
-- we glob /nix/store for the matching version.
if not vim.g.remote_neovim_host and vim.fn.executable("magick") == 1 then
  local bin = vim.fn.exepath("magick")
  local resolved = vim.fn.resolve(bin)
  -- /nix/store/HASH-imagemagick-VERSION/bin/magick → /nix/store/HASH-imagemagick-VERSION
  local runtime_prefix = vim.fn.fnamemodify(resolved, ":h:h")

  -- Runtime: ffi.load needs libMagickWand on the dyld search path
  local lib_dir = runtime_prefix .. "/lib"
  if vim.fn.isdirectory(lib_dir) == 1 then
    local existing = vim.env.DYLD_LIBRARY_PATH or ""
    vim.env.DYLD_LIBRARY_PATH = lib_dir .. (existing ~= "" and (":" .. existing) or "")
  end

  -- macOS: the magick LuaRock does `ffi.load("MagickWand")`, which dlopen
  -- translates to libMagickWand.dylib (bare name). Nix's imagemagick only
  -- ships the variant-suffixed file (libMagickWand-7.Q16HDRI.dylib) — no
  -- bare-name symlink — so the load fails. Build a shim directory with
  -- bare-name symlinks and prepend it to DYLD_LIBRARY_PATH.
  if vim.fn.has("mac") == 1 and vim.fn.isdirectory(lib_dir) == 1 then
    local shim_dir = vim.fn.stdpath("cache") .. "/magick-shim"
    vim.fn.mkdir(shim_dir, "p")
    for _, name in ipairs({ "MagickWand", "MagickCore" }) do
      local matches = vim.fn.glob(lib_dir .. "/lib" .. name .. "-*.dylib", false, true)
      -- Prefer the unversioned variant (libMagickWand-7.Q16HDRI.dylib) over
      -- the soversion-suffixed alias (libMagickWand-7.Q16HDRI.10.dylib).
      local target
      for _, m in ipairs(matches) do
        if not vim.fn.fnamemodify(m, ":t"):match("%.%d+%.dylib$") then
          target = m
          break
        end
      end
      target = target or matches[1]
      if target then
        local link = shim_dir .. "/lib" .. name .. ".dylib"
        if vim.fn.filereadable(link) ~= 1 then
          pcall((vim.uv or vim.loop).fs_symlink, target, link)
        end
      end
    end
    local existing = vim.env.DYLD_LIBRARY_PATH or ""
    if not existing:find(shim_dir, 1, true) then
      vim.env.DYLD_LIBRARY_PATH = shim_dir .. (existing ~= "" and (":" .. existing) or "")
    end
  end

  -- Build-time: pkg-config needs MagickWand.pc, which lives in the dev output.
  -- Try the runtime prefix first (some platforms co-locate .pc files), then
  -- fall back to scanning the Nix store for a matching `-dev` output.
  local pc_candidates = { runtime_prefix .. "/lib/pkgconfig" }
  local version = (resolved:match("imagemagick%-([%d%.%-]+)/bin/magick$") or ""):gsub("%-$", "")
  if version ~= "" then
    local hits = vim.fn.glob("/nix/store/*-imagemagick-" .. version .. "-dev/lib/pkgconfig", false, true)
    for _, p in ipairs(hits) do
      pc_candidates[#pc_candidates + 1] = p
    end
  end
  for _, pc_dir in ipairs(pc_candidates) do
    if vim.fn.filereadable(pc_dir .. "/MagickWand.pc") == 1 then
      local existing = vim.env.PKG_CONFIG_PATH or ""
      vim.env.PKG_CONFIG_PATH = pc_dir .. (existing ~= "" and (":" .. existing) or "")
      break
    end
  end
end

require("config.lazy")

-- Built-in OSC52 clipboard (copy-only)
local has_osc52, osc52 = pcall(require, "vim.ui.clipboard.osc52")

if has_osc52 then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    -- Do not try to *read* via OSC52 (many terminals disallow it).
    paste = {
      ["+"] = function()
        return { { "" }, "v" }
      end,
      ["*"] = function()
        return { { "" }, "v" }
      end,
    },
    cache_enabled = 0,
  }
end

-- Optional: make all yanks use the + register
vim.opt.clipboard = ""
vim.keymap.set("v", "<D-c>", '"+y', { silent = true })
vim.keymap.set("n", "<D-c>", '"+yy', { silent = true })
