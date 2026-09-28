-- 终端键位
local function term_nav(dir)
  ---@param self snacks.terminal
  return function(self)
    return self:is_floating() and "<c-" .. dir .. ">" or vim.schedule(function()
      vim.cmd.wincmd(dir)
    end)
  end
end

return {

  -- Snacks 工具
  {
    "snacks.nvim",
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      terminal = {
        win = {
          keys = {
            nav_h = { "<C-h>", term_nav("h"), desc = "跳到左侧窗口", expr = true, mode = "t" },
            nav_j = { "<C-j>", term_nav("j"), desc = "跳到下方窗口", expr = true, mode = "t" },
            nav_k = { "<C-k>", term_nav("k"), desc = "跳到上方窗口", expr = true, mode = "t" },
            nav_l = { "<C-l>", term_nav("l"), desc = "跳到右侧窗口", expr = true, mode = "t" },
            hide_slash = { "<C-/>", "hide", desc = "隐藏终端", mode = "t" },
            hide_underscore = { "<c-_>", "hide", desc = "which_key_ignore", mode = "t" },
          },
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>.",  function() Snacks.scratch() end, desc = "切换草稿缓冲区" },
      { "<leader>S",  function() Snacks.scratch.select() end, desc = "选择草稿缓冲区" },
      { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "性能分析草稿缓冲区" },
    },
  },

  -- 会话管理。它会在后台保存你的会话，
  -- 记录已打开的缓冲区、窗口布局等信息。
  -- 你可以通过启动界面恢复会话。
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    -- stylua: ignore
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "恢复会话" },
      { "<leader>qS", function() require("persistence").select() end,desc = "选择会话" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "恢复上次会话" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "不保存当前会话" },
    },
  },

  -- 供其它插件使用的库
  { "nvim-lua/plenary.nvim", lazy = true },
}
