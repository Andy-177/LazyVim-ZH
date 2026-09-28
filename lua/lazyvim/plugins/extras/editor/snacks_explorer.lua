return {
  desc = "Snacks 文件浏览器",
  recommended = true,
  "folke/snacks.nvim",
  opts = { explorer = {} },
  keys = {
    {
      "<leader>fe",
      function()
        Snacks.explorer({ cwd = LazyVim.root() })
      end,
      desc = "文件浏览器 Snacks（根目录）",
    },
    {
      "<leader>fE",
      function()
        Snacks.explorer()
      end,
      desc = "文件浏览器 Snacks（cwd）",
    },
    { "<leader>e", "<leader>fe", desc = "文件浏览器 Snacks（根目录）", remap = true },
    { "<leader>E", "<leader>fE", desc = "文件浏览器 Snacks（cwd）", remap = true },
  },
}
