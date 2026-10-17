-- Annotate code in nvim, sync comments to .code-review.md, let an agent apply them.
-- Keys: <leader>ra add, <leader>rd delete, <leader>rl list, <leader>rx clear
return {
  "scristobal/code-review.nvim",
  opts = {},
  keys = {
    { "<leader>r", "", desc = "+Comments", mode = { "n", "x" } },
  },
}
