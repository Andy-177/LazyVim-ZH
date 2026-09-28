if vim.fn.has("nvim-0.11.2") == 0 then
  vim.api.nvim_echo({
    { { "LazyVim 需要 Neovim >= 0.11.2\n", "ErrorMsg" },
      { "更多信息请参见：https://github.com/LazyVim/LazyVim/issues/6421\n", "Comment" },
      { "按任意键退出", "MoreMsg" },
    },
  }, true, {})
  vim.fn.getchar()
  vim.cmd([[quit]])
  return {}
end

require("lazyvim.config").init()

return {
  { "folke/lazy.nvim", version = "*" },
  { "LazyVim/LazyVim", priority = 10000, lazy = false, opts = {}, cond = true, version = "*" },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {},
    config = function(_, opts)
      local notify = vim.notify
      require("snacks").setup(opts)
      -- 变通方案：在 snacks 设置完成后恢复 vim.notify，并让 noice.nvim 接管
      -- 这样早期通知才会显示在 noice 历史记录中
      if LazyVim.has("noice.nvim") then
        vim.notify = notify
      end
    end,
  },
}
