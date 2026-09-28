return {
  desc = "Aerial 符号浏览器",
  {
    "stevearc/aerial.nvim",
    event = "LazyFile",
    opts = function()
      local icons = vim.deepcopy(LazyVim.config.icons.kinds)

      -- HACK：修正 lua 把 `Package` 当作控制结构的奇怪写法
      -- 比如 if/else/for 等
      icons.lua = { Package = icons.Control }

      ---@type table<string, string[]>|false
      local filter_kind = false
      if LazyVim.config.kind_filter then
        filter_kind = assert(vim.deepcopy(LazyVim.config.kind_filter))
        filter_kind._ = filter_kind.default
        filter_kind.default = nil
      end

      local opts = {
        attach_mode = "global",
        backends = { "lsp", "treesitter", "markdown", "man" },
        show_guides = true,
        layout = {
          resize_to_content = false,
          win_opts = {
            winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
            signcolumn = "yes",
            statuscolumn = " ",
          },
        },
        icons = icons,
        filter_kind = filter_kind,
        -- stylua: ignore
        guides = {
          mid_item   = "├╴",
          last_item  = "└╴",
          nested_top = "│ ",
          whitespace = "  ",
        },
      }
      return opts
    end,
    keys = {
      { "<leader>cs", "<cmd>AerialToggle<cr>", desc = "Aerial（符号）" },
    },
  },

  {
    "folke/trouble.nvim",
    optional = true,
    keys = {
      { "<leader>cs", false },
    },
  },

  -- Telescope 集成
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    opts = function()
      LazyVim.on_load("telescope.nvim", function()
        require("telescope").load_extension("aerial")
      end)
    end,
    keys = {
      {
        "<leader>ss",
        "<cmd>Telescope aerial<cr>",
        desc = "转到符号 (Aerial)",
      },
    },
  },

  -- edgy 集成
  {
    "folke/edgy.nvim",
    optional = true,
    opts = function(_, opts)
      local edgy_idx = LazyVim.plugin.extra_idx("ui.edgy")
      local aerial_idx = LazyVim.plugin.extra_idx("editor.aerial")

      if edgy_idx and edgy_idx > aerial_idx then
        LazyVim.warn("必须先 **导入** `edgy.nvim` extra，再导入 `aerial.nvim` extra，才能正常工作。", {
          title = "LazyVim",
        })
      end

      opts.right = opts.right or {}
      table.insert(opts.right, {
        title = "Aerial",
        ft = "aerial",
        pinned = true,
        open = "AerialOpen",
      })
    end,
  },

  -- lualine 集成
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      if not vim.g.trouble_lualine then
        table.insert(opts.sections.lualine_c, {
          "aerial",
          sep = " ", -- separator between symbols
          sep_icon = "", -- separator between icon and symbol

          -- 从上到下渲染的符号数量。要只渲染最后 'N' 个符号，
          -- 可以传入负数。例如 'depth = -1' 会只渲染当前符号。
          depth = 5,

          -- 启用 'dense' 模式时，不会在符号旁渲染图标。只会在
          -- 状态栏开头渲染一个代表当前符号种类的图标。
          dense = false,

          -- dense 模式下用于分隔符号的分隔符。
          dense_sep = ".",

          -- 为符号图标着色。
          colored = true,
        })
      end
    end,
  },
}
