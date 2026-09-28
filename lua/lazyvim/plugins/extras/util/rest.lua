vim.filetype.add({
  extension = {
    ["http"] = "http",
  },
})
return {
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    keys = {
      { "<leader>R", "", desc = "+Rest" },
      { "<leader>Rb", "<cmd>lua require('kulala').scratchpad()<cr>", desc = "打开草稿板" },
      { "<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", desc = "复制为 cURL", ft = "http" },
      { "<leader>RC", "<cmd>lua require('kulala').from_curl()<cr>", desc = "从 curl 粘贴", ft = "http" },
      { "<leader>Re", "<cmd>lua require('kulala').set_selected_env()<cr>", desc = "设置环境", ft = "http" },
      {
        "<leader>Rg",
        "<cmd>lua require('kulala').download_graphql_schema()<cr>",
        desc = "下载 GraphQL schema",
        ft = "http",
      },
      { "<leader>Ri", "<cmd>lua require('kulala').inspect()<cr>", desc = "检查当前请求", ft = "http" },
      { "<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>", desc = "跳到下一个请求", ft = "http" },
      { "<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "跳到上一个请求", ft = "http" },
      { "<leader>Rq", "<cmd>lua require('kulala').close()<cr>", desc = "关闭窗口", ft = "http" },
      { "<leader>Rr", "<cmd>lua require('kulala').replay()<cr>", desc = "重放上一个请求" },
      { "<leader>Rs", "<cmd>lua require('kulala').run()<cr>", desc = "发送请求", ft = "http" },
      { "<leader>RS", "<cmd>lua require('kulala').show_stats()<cr>", desc = "显示统计", ft = "http" },
      { "<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>", desc = "切换头部/主体", ft = "http" },
    },
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "http", "graphql" },
    },
  },
}
