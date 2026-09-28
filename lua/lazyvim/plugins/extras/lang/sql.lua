if lazyvim_docs then
  -- 下面的配置会自动完成连接设置，无需每次手动输入。

  -- 使用带键的字典进行配置示例：
  --    vim.g.dbs = {
  --      dev = "替换为你的数据库连接 URL。",
  --      staging = "替换为你的数据库连接 URL。",
  --    }
  -- 或者
  -- 使用字典列表进行配置示例：
  --    vim.g.dbs = {
  --      { name = "dev", url = "替换为你的数据库连接 URL。" },
  --      { name = "staging", url = "替换为你的数据库连接 URL。" },
  --    }

  -- 或者
  -- 在你的项目中创建 `.lazy.lua` 文件，并像这样设置连接：
  -- ```lua
  --    vim.g.dbs = {...}
  --
  --    return {}
  -- ```

  -- 或者，你也可以使用其他方式注入环境变量。

  -- 最后，请确保将 `.lazy.lua` 添加到 `.gitignore` 文件中，以保护你的密钥。
end

local sql_ft = { "sql", "mysql", "plsql" }

-- 禁用 nvim 默认的 `sql_completion` 插件，以兼容 blink.cmp 的 omni
-- 同时仍然显示语法自动补全来源中的部分关键字
vim.g.omni_sql_default_compl_type = "syntax"
vim.g.loaded_sql_completion = true

return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = sql_ft,
    })
  end,

  {
    "tpope/vim-dadbod",
    cmd = "DB",
  },

  {
    "kristijanhusak/vim-dadbod-completion",
    dependencies = "vim-dadbod",
    ft = sql_ft,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = sql_ft,
        callback = function()
          if LazyVim.has_extra("coding.nvim-cmp") then
            local cmp = require("cmp")

            -- 全局来源
            ---@param source cmp.SourceConfig
            local sources = vim.tbl_map(function(source)
              return { name = source.name }
            end, cmp.get_config().sources)

            -- 添加 vim-dadbod-completion 来源
            table.insert(sources, { name = "vim-dadbod-completion" })

            -- 更新当前缓冲区的来源
            cmp.setup.buffer({ sources = sources })
          end
        end,
      })
    end,
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = "vim-dadbod",
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<CR>", desc = "切换 DBUI" },
    },
    init = function()
      local data_path = vim.fn.stdpath("data")

      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_use_nvim_notify = true

      -- 注意：保存时自动执行查询的默认行为是禁用的
      -- 当你有一个不想每次都运行的大查询时，这会很有用
      -- 保存文件时运行这些查询可能导致 neovim 崩溃，要运行请使用
      -- 默认键位：<leader>S
      vim.g.db_ui_execute_on_save = false
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = { ensure_installed = { "sql" } },
  },

  -- edgy 集成
  {
    "folke/edgy.nvim",
    optional = true,
    opts = function(_, opts)
      opts.right = opts.right or {}
      table.insert(opts.right, {
        title = "数据库",
        ft = "dbui",
        pinned = true,
        width = 0.3,
        open = function()
          vim.cmd("DBUI")
        end,
      })

      opts.bottom = opts.bottom or {}
      table.insert(opts.bottom, {
        title = "数据库查询结果",
        ft = "dbout",
      })
    end,
  },

  -- blink.cmp 集成
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        default = { "dadbod" },
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
    dependencies = {
      "kristijanhusak/vim-dadbod-completion",
    },
  },

  -- 代码检查器与格式化工具
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "sqlfluff" } },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      for _, ft in ipairs(sql_ft) do
        opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
        table.insert(opts.linters_by_ft[ft], "sqlfluff")
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters.sqlfluff = {
        args = { "format", "--dialect=ansi", "-" },
      }
      for _, ft in ipairs(sql_ft) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "sqlfluff")
      end
    end,
  },
}
