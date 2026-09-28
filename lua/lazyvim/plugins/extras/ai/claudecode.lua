return {
  "coder/claudecode.nvim",
  opts = {},
  keys = {
    { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "切换 Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "聚焦 Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "恢复 Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "继续 Claude" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "添加当前缓冲区" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "发送到 Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "添加文件",
      ft = { "NvimTree", "neo-tree", "oil" },
    },
    -- 差异管理
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "接受差异" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "拒绝差异" },
  },
}
