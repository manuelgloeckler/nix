-- Annotate code in nvim, sync comments to .code-review.md, let an agent apply them.
-- Keys: <leader>ra add, <leader>rd delete, <leader>rl list, <leader>rx clear,
--       <leader>rt add from template (works in normal + visual mode)

local templates = {
  { "Missing test",   "Missing test coverage — please add a test for this case." },
  { "Error handling", "Unhandled error case — handle this explicitly." },
  { "Edge case",      "Edge case not handled — consider what happens here." },
  { "Security",       "Potential security issue — review for injection / unsafe input." },
  { "Performance",    "Possible performance concern — consider optimizing this." },
  { "Clarity",        "Naming / clarity — this is hard to follow, please simplify." },
  { "Duplication",    "Duplicated logic — extract this into a shared helper." },
  { "Docs",           "Missing docs — add a brief comment explaining intent." },
}

-- Capture the target range before any UI opens (a visual selection ends once a prompt shows).
local function range()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local s = vim.fn.getpos("v")[2]
    local e = vim.fn.getpos(".")[2]
    if s > e then s, e = e, s end
    vim.cmd("normal! \27")
    return s, e
  end
  local l = vim.fn.line(".")
  return l, l
end

local function add_from_template()
  local review = require("review")
  local start, stop = range()

  vim.ui.select(templates, {
    prompt = "Review template",
    format_item = function(t) return t[1] end,
  }, function(choice)
    if not choice then return end

    -- Prefill vim.ui.input with the template, then restore the original.
    local orig = vim.ui.input
    vim.ui.input = function(opts, cb)
      opts = opts or {}
      opts.default = choice[2]
      local r = orig(opts, cb)
      vim.ui.input = orig
      return r
    end
    review.add(start, stop)
    vim.ui.input = orig
  end)
end

-- Registered at top level so it always exists (the plugin's own keys come from setup()).
vim.keymap.set({ "n", "x" }, "<leader>rt", add_from_template, {
  desc = "Review: add from template",
})

return {
  "scristobal/code-review.nvim",
  main = "review",
  lazy = false,
  opts = {},
  keys = {
    { "<leader>r", "", desc = "+Comments", mode = { "n", "x" } },
  },
}
