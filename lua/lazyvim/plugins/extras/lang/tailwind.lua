return {
  recommended = function()
    return LazyVim.extras.wants({
      root = {
        "tailwind.config.js",
        "tailwind.config.cjs",
        "tailwind.config.mjs",
        "tailwind.config.ts",
        "postcss.config.js",
        "postcss.config.cjs",
        "postcss.config.mjs",
        "postcss.config.ts",
      },
    })
  end,
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tailwindcss = {
          -- 从 default_config 中排除某个文件类型
          filetypes_exclude = { "markdown" },
          -- 为 default_config 额外添加文件类型
          filetypes_include = {},
          -- 若要完全覆盖 default_config，请修改下面这行
          -- filetypes = {}

          -- 服务器的额外设置，例如：
          -- tailwindCSS = { includeLanguages = { someLang = "html" } }
          -- 可以添加到 settings 表中，并会与下面的默认值合并
          -- 这部分 Phoenix 项目的默认值
          settings = {
            tailwindCSS = {
              includeLanguages = {
                elixir = "html-eex",
                eelixir = "html-eex",
                heex = "html-eex",
              },
            },
          },
        },
      },
      setup = {
        tailwindcss = function(_, opts)
          opts.filetypes = opts.filetypes or {}

          -- 添加默认文件类型
          vim.list_extend(opts.filetypes, vim.lsp.config.tailwindcss.filetypes)

          -- 移除被排除的文件类型
          --- @param ft string
          opts.filetypes = vim.tbl_filter(function(ft)
            return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
          end, opts.filetypes)

          -- 添加额外的文件类型
          vim.list_extend(opts.filetypes, opts.filetypes_include or {})
        end,
      },
    },
  },
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = {
      { "roobert/tailwindcss-colorizer-cmp.nvim", opts = {} },
    },
    opts = function(_, opts)
      -- 原有的 LazyVim kind 图标格式化器
      local format_kinds = opts.formatting.format
      opts.formatting.format = function(entry, item)
        format_kinds(entry, item) -- add icons
        return require("tailwindcss-colorizer-cmp").formatter(entry, item)
      end
    end,
  },
}
