-- 更好的 yank/paste
return {
  "gbprod/yanky.nvim",
  recommended = true,
  desc = "更好的 Yank/Paste",
  event = "LazyFile",
  opts = {
    system_clipboard = {
      sync_with_ring = not vim.env.SSH_CONNECTION,
    },
    highlight = { timer = 150 },
  },
  keys = {
    {
      "<leader>p",
      function()
        if LazyVim.pick.picker.name == "telescope" then
          require("telescope").extensions.yank_history.yank_history({})
        elseif LazyVim.pick.picker.name == "snacks" then
          Snacks.picker.yanky()
        else
          vim.cmd([[YankyRingHistory]])
        end
      end,
      mode = { "n", "x" },
      desc = "打开 Yank 历史",
    },
        -- stylua: ignore
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank 文本" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "在光标后放置文本" },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "在光标前放置文本" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "在选区后放置文本" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "在选区前放置文本" },
    { "[y", "<Plug>(YankyCycleForward)", desc = "正向遍历 Yank 历史" },
    { "]y", "<Plug>(YankyCycleBackward)", desc = "反向遍历 Yank 历史" },
    { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "在光标后放置缩进文本（按行）" },
    { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "在光标前放置缩进文本（按行）" },
    { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "在光标后放置缩进文本（按行）" },
    { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "在光标前放置缩进文本（按行）" },
    { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "放置并向右缩进" },
    { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "放置并向左缩进" },
    { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "在前方放置并向右缩进" },
    { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "在前方放置并向左缩进" },
    { "=p", "<Plug>(YankyPutAfterFilter)", desc = "应用过滤器后放置" },
    { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "应用过滤器前放置" },
  },
}
