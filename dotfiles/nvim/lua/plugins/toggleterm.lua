-- Pick your percentages here
local H_PCT = 0.30 -- 30% of editor height for horizontal terminals
local V_PCT = 0.40 -- 40% of editor width  for vertical terminals

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    -- size can be a function; ToggleTerm calls it when opening a terminal
    size = function(term)
      if term.direction == "horizontal" then
        return math.floor(vim.o.lines * H_PCT)
      elseif term.direction == "vertical" then
        return math.floor(vim.o.columns * V_PCT)
      end
      return 20
    end,
    -- Optional: set a default direction
    direction = "horizontal",
  },
  config = function(_, opts)
    local ok, toggleterm = pcall(require, "toggleterm")
    if not ok then
      return
    end
    toggleterm.setup(opts)
  end,
  keys = {
    { "<leader>T", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
  },
}
