return {
  recommended = true,
  -- copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "BufReadPost",
    opts = {
      suggestion = {
        enabled = not vim.g.ai_cmp,
        auto_trigger = true,
        hide_during_completion = vim.g.ai_cmp,
        keymap = {
          accept = false, -- 由 nvim-cmp / blink.cmp 处理
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },

  -- copilot-language-server
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- copilot.lua 只能配合它自带的 copilot lsp 服务器使用
        copilot = { enabled = false },
      },
    },
  },

  -- 添加 ai_accept 操作
  {
    "zbirenbaum/copilot.lua",
    opts = function()
      LazyVim.cmp.actions.ai_accept = function()
        if require("copilot.suggestion").is_visible() then
          LazyVim.create_undo()
          require("copilot.suggestion").accept()
          return true
        end
      end
    end,
  },

  -- lualine
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(
        opts.sections.lualine_x,
        2,
        LazyVim.lualine.status(LazyVim.config.icons.kinds.Copilot, function()
          local clients = package.loaded["copilot"] and vim.lsp.get_clients({ name = "copilot", bufnr = 0 }) or {}
          if #clients > 0 then
            local status = require("copilot.status").data.status
            return (status == "InProgress" and "pending") or (status == "Warning" and "error") or "ok"
          end
        end)
      )
    end,
  },

  vim.g.ai_cmp and {
    -- copilot cmp 数据源
    {
      "hrsh7th/nvim-cmp",
      optional = true,
      dependencies = { -- 仅在启用 nvim-cmp 时才会被求值
        {
          "zbirenbaum/copilot-cmp",
          opts = {},
          config = function(_, opts)
            local copilot_cmp = require("copilot_cmp")
            copilot_cmp.setup(opts)
            -- 每当 copilot 挂载时就挂载 cmp 数据源
            -- 修复 copilot cmp 数据源的懒加载问题
            Snacks.util.lsp.on({ name = "copilot" }, function()
              copilot_cmp._on_insert_enter({})
            end)
          end,
          specs = {
            {
              "hrsh7th/nvim-cmp",
              optional = true,
              ---@param opts cmp.ConfigSchema
              opts = function(_, opts)
                table.insert(opts.sources, 1, {
                  name = "copilot",
                  group_index = 1,
                  priority = 100,
                })
              end,
            },
          },
        },
      },
    },
    {
      "saghen/blink.cmp",
      optional = true,
      dependencies = { "fang2hou/blink-copilot" },
      opts = {
        sources = {
          default = { "copilot" },
          providers = {
            copilot = {
              name = "copilot",
              module = "blink-copilot",
              score_offset = 100,
              async = true,
            },
          },
        },
      },
    },
  } or nil,
}
