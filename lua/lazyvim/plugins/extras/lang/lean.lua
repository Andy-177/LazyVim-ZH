return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = { "lean" },
      root = { "lean-toolchain" },
    })
  end,
  "Julian/lean.nvim",
  event = { "BufReadPre *.lean", "BufNewFile *.lean" },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  -- 完整的配置选项请参见下文
  opts = {
    -- 是否启用 Lean 语言服务器？
    --
    -- 设为 false 表示禁用，否则应为传递给 `leanls` 的选项表
    --
    -- 详情参见 https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#leanls 。
    -- 尤其要确保你已按照说明设置好 `LspAttach` 的回调，
    -- 该回调用于设置你的键位！
    lsp = {
      init_options = {
        -- 更多选项和详情参见 Lean.Lsp.InitializationOptions。

        -- 从最近一次编辑到开始 elaboration 之前必须经过的时间（毫秒）。
        -- 该值越小编辑感觉越快，但 CPU 占用会更高。
        -- 注意 lean.nvim 修改了 Lean 对该值的默认值！
        editDelay = 0,

        -- 是否声明支持 widgets。
        hasWidgets = true,
      },
    },

    ft = {
      -- 用于匹配的模式列表，可防止匹配的
      -- Lean 文件路径被意外修改（通过将缓冲区
      -- 标记为 `nomodifiable`）。
      nomodifiable = {
        -- 默认情况下，该列表包含 Lean 标准库，
        -- 以及依赖目录中的文件（例如 `_target`）
        -- 设为空表即可禁用。
      },
    },

    -- 缩写支持
    abbreviations = {
      -- 是否启用 unicode 缩写的展开？
      enable = true,
      -- 额外缩写：
      extra = {
        -- 添加一个 \wknight 缩写用于插入 ♘
        --
        -- 注意反斜杠是隐含的，当然你也可以直接使用
        -- 片段引擎来完成同样的事情。
        wknight = "♘",
      },
      -- 如果你不喜欢反斜杠，可以改成别的
      -- （在法语键盘上逗号是常见选择）
      leader = "\\",
    },

    -- 是否启用推荐的键位映射？
    --
    -- 默认 false，设为 true 启用
    mappings = true,

    -- Infoview 支持
    infoview = {
      -- 进入 Lean 缓冲区时是否自动打开 infoview？
      -- 应为一个函数，每次打开新的 Lean 文件时都会调用。
      -- 返回 true 则打开 infoview，否则返回 false。
      -- 设为 `true` 等同于 `function() return true end`，
      -- 即对任意 Lean 文件都自动打开；设为 `false` 则
      -- 等同于 `function() return false end`，即永不自动打开。
      autoopen = true,

      -- 设置 infoview 窗口的初始尺寸。
      -- 窗口会根据间距以水平或垂直方式打开。
      width = 50,
      height = 20,

      -- 水平放置时，infoview 位于上方还是下方？
      -- top | bottom
      horizontal_position = "bottom",

      -- 是否总在单独的标签页中打开 infoview 窗口。
      -- 如果你在使用屏幕阅读器，不希望终端中同时出现
      -- 太多动态更新，这个选项会很有用。
      -- 注意此时 `height` 和 `width` 将被忽略。
      separate_tab = false,

      -- 进入 infoview 窗口时是否显示固定位置的指示器？
      -- always | never | auto（= 仅当存在多个固定位置时）
      indicators = "auto",
    },

    -- 进度条支持
    progress_bars = {
      -- 是否启用进度条？
      enable = true,
      -- 进度条使用什么字符？
      character = "│",
      -- 为符号标记使用不同的优先级
      priority = 10,
    },

    -- 将 Lean 的 stderr 消息重定向到某处（默认输出到缓冲区）
    stderr = {
      enable = true,
      -- 窗口高度
      height = 5,
      -- 接收（多行）stderr 输出的回调
      -- 例如使用：
      --   on_lines = function(lines) vim.notify(lines) end
      -- 即可把 stderr 重定向到 `vim.notify`。
      -- 默认实现会重定向到专用的 stderr
      -- 窗口。
      on_lines = nil,
    },
  },
}
