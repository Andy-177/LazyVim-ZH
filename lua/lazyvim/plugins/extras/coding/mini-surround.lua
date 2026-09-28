-- 快速且功能丰富的包围操作。对于包含
-- 括号或引号等包围字符的文本，它可以让你
-- 选中内部文本、更改或修改包围字符、
-- 等等。
return {
  "nvim-mini/mini.surround",
  keys = function(_, keys)
    -- 根据用户选项填充按键
    local opts = LazyVim.opts("mini.surround")
    local mappings = {
      { opts.mappings.add, desc = "添加包围", mode = { "n", "x" } },
      { opts.mappings.delete, desc = "删除包围" },
      { opts.mappings.find, desc = "查找右侧包围符" },
      { opts.mappings.find_left, desc = "查找左侧包围符" },
      { opts.mappings.highlight, desc = "高亮包围符" },
      { opts.mappings.replace, desc = "替换包围符" },
      { opts.mappings.update_n_lines, desc = "更新 `MiniSurround.config.n_lines`" },
    }
    mappings = vim.tbl_filter(function(m)
      return m[1] and #m[1] > 0
    end, mappings)
    return vim.list_extend(mappings, keys)
  end,
  opts = {
    mappings = {
      add = "gsa", -- Add surrounding in Normal and Visual modes
      delete = "gsd", -- Delete surrounding
      find = "gsf", -- Find surrounding (to the right)
      find_left = "gsF", -- Find surrounding (to the left)
      highlight = "gsh", -- Highlight surrounding
      replace = "gsr", -- Replace surrounding
      update_n_lines = "gsn", -- Update `n_lines`
    },
  },
}
