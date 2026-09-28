vim.api.nvim_echo({
  {
    "请勿直接使用本仓库\n",
    "ErrorMsg",
  },
  {
    "请查看文档以了解如何开始使用 LazyVim\n",
    "WarningMsg",
  },
  { "按任意键退出", "MoreMsg" },
}, true, {})

vim.fn.getchar()
vim.cmd([[quit]])
