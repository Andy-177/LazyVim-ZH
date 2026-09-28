return {
  -- 禁用 flash
  { "folke/flash.nvim", enabled = false, optional = true },

  -- 轻松跳转到任意位置，并为 Leap 增强 f/t 移动
  {
    url = "https://codeberg.org/andyg/leap.nvim.git",
    enabled = true,
    keys = function()
      ---@type LazyKeysSpec[]
      local ret = {}
      for _, key in ipairs({ "f", "F", "t", "T" }) do
        ret[#ret + 1] = { key, mode = { "n", "x", "o" } }
      end
      return ret
    end,
    opts = { labeled_modes = "nx" },
  },
  {
    url = "https://codeberg.org/andyg/leap.nvim.git",
    enabled = true,
    keys = {
      { "s", mode = { "n", "x", "o" }, desc = "Leap 向前跳到" },
      { "S", mode = { "n", "x", "o" }, desc = "Leap 向后跳到" },
      { "gs", mode = { "n", "x", "o" }, desc = "从窗口 Leap" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      leap.add_default_mappings(true)
      vim.keymap.del({ "x", "o" }, "x")
      vim.keymap.del({ "x", "o" }, "X")
    end,
  },

  -- 将 surround 映射从 gs 重命名为 gz，以避免与 leap 冲突
  {
    "nvim-mini/mini.surround",
    optional = true,
    opts = {
      mappings = {
        add = "gza", -- Add surrounding in Normal and Visual modes
        delete = "gzd", -- Delete surrounding
        find = "gzf", -- Find surrounding (to the right)
        find_left = "gzF", -- Find surrounding (to the left)
        highlight = "gzh", -- Highlight surrounding
        replace = "gzr", -- Replace surrounding
        update_n_lines = "gzn", -- Update `n_lines`
      },
    },
    keys = {
      { "gz", "", desc = "+surround" },
    },
  },

  -- 让一些插件像 leap 一样支持点重复
  { "tpope/vim-repeat", event = "VeryLazy" },
}
