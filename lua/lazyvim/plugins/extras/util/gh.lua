return {

  -- 依赖 git 扩展来高亮和自动补全 github 的 issue/pr
  { import = "lazyvim.plugins.extras.lang.git" },

  { "ldelossa/litee.nvim", lazy = true },

  -- gh.nvim
  {
    "ldelossa/gh.nvim",
    opts = {},
    config = function(_, opts)
      require("litee.lib").setup()
      require("litee.gh").setup(opts)
    end,
    keys = {
      { "<leader>G", "", desc = "+Github" },
      { "<leader>Gc", "", desc = "+Commits" },
      { "<leader>Gcc", "<cmd>GHCloseCommit<cr>", desc = "关闭" },
      { "<leader>Gce", "<cmd>GHExpandCommit<cr>", desc = "展开" },
      { "<leader>Gco", "<cmd>GHOpenToCommit<cr>", desc = "打开到" },
      { "<leader>Gcp", "<cmd>GHPopOutCommit<cr>", desc = "弹出" },
      { "<leader>Gcz", "<cmd>GHCollapseCommit<cr>", desc = "折叠" },
      { "<leader>Gi", "", desc = "+Issues" },
      { "<leader>Gip", "<cmd>GHPreviewIssue<cr>", desc = "预览" },
      { "<leader>Gio", "<cmd>GHOpenIssue<cr>", desc = "打开" },
      { "<leader>Gl", "", desc = "+Litee" },
      { "<leader>Glt", "<cmd>LTPanel<cr>", desc = "切换面板" },
      { "<leader>Gp", "", desc = "+Pull Request" },
      { "<leader>Gpc", "<cmd>GHClosePR<cr>", desc = "关闭" },
      { "<leader>Gpd", "<cmd>GHPRDetails<cr>", desc = "详情" },
      { "<leader>Gpe", "<cmd>GHExpandPR<cr>", desc = "展开" },
      { "<leader>Gpo", "<cmd>GHOpenPR<cr>", desc = "打开" },
      { "<leader>Gpp", "<cmd>GHPopOutPR<cr>", desc = "弹出" },
      { "<leader>Gpr", "<cmd>GHRefreshPR<cr>", desc = "刷新" },
      { "<leader>Gpt", "<cmd>GHOpenToPR<cr>", desc = "打开到" },
      { "<leader>Gpz", "<cmd>GHCollapsePR<cr>", desc = "折叠" },
      { "<leader>Gr", "", desc = "+Review" },
      { "<leader>Grb", "<cmd>GHStartReview<cr>", desc = "开始" },
      { "<leader>Grc", "<cmd>GHCloseReview<cr>", desc = "关闭" },
      { "<leader>Grd", "<cmd>GHDeleteReview<cr>", desc = "删除" },
      { "<leader>Gre", "<cmd>GHExpandReview<cr>", desc = "展开" },
      { "<leader>Grs", "<cmd>GHSubmitReview<cr>", desc = "提交" },
      { "<leader>Grz", "<cmd>GHCollapseReview<cr>", desc = "折叠" },
      { "<leader>Gt", "", desc = "+Threads" },
      { "<leader>Gtc", "<cmd>GHCreateThread<cr>", desc = "创建" },
      { "<leader>Gtn", "<cmd>GHNextThread<cr>", desc = "下一个" },
      { "<leader>Gtt", "<cmd>GHToggleThread<cr>", desc = "切换" },
    },
  },
}
