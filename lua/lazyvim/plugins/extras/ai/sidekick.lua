return {
  desc = "使用 Copilot LSP 服务器的下一处编辑建议",

  -- copilot-language-server
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local sk = LazyVim.opts("sidekick.nvim") ---@type sidekick.Config|{}
      if vim.tbl_get(sk, "nes", "enabled") ~= false then
        opts.servers = opts.servers or {}
        opts.servers.copilot = opts.servers.copilot or {}
      end
    end,
  },

  -- lualine
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    opts = function(_, opts)
      local icons = {
        Error = { " ", "DiagnosticError" },
        Inactive = { " ", "MsgArea" },
        Warning = { " ", "DiagnosticWarn" },
        Normal = { LazyVim.config.icons.kinds.Copilot, "Special" },
      }
      table.insert(opts.sections.lualine_x, 2, {
        function()
          local status = require("sidekick.status").get()
          return status and vim.tbl_get(icons, status.kind, 1)
        end,
        cond = function()
          return require("sidekick.status").get() ~= nil
        end,
        color = function()
          local status = require("sidekick.status").get()
          local hl = status and (status.busy and "DiagnosticWarn" or vim.tbl_get(icons, status.kind, 2))
          return { fg = Snacks.util.color(hl) }
        end,
      })

      table.insert(opts.sections.lualine_x, 2, {
        function()
          local status = require("sidekick.status").cli()
          return " " .. (#status > 1 and #status or "")
        end,
        cond = function()
          return #require("sidekick.status").cli() > 0
        end,
        color = function()
          return { fg = Snacks.util.color("Special") }
        end,
      })
    end,
  },

  {
    "folke/sidekick.nvim",
    opts = function()
      -- 接受内联建议或后续编辑
      LazyVim.cmp.actions.ai_nes = function()
        local Nes = require("sidekick.nes")
        if Nes.have() and (Nes.jump() or Nes.apply()) then
          return true
        end
      end
      Snacks.toggle({
        name = "Sidekick NES",
        get = function()
          return require("sidekick.nes").enabled
        end,
        set = function(state)
          require("sidekick.nes").enable(state)
        end,
      }):map("<leader>uN")
    end,
    -- stylua: ignore
    keys = {
      -- nes 在普通模式下也很有用
      { "<tab>", LazyVim.cmp.map({ "ai_nes" }, "<tab>"), mode = { "n" }, expr = true },
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      {
        "<c-.>",
        function() require("sidekick.cli").focus() end,
        desc = "Sidekick 聚焦",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>aa",
        function() require("sidekick.cli").toggle() end,
        desc = "Sidekick 切换 CLI",
      },
      {
        "<leader>as",
        function() require("sidekick.cli").select() end,
        -- 或者只选择已安装的工具：
        -- require("sidekick.cli").select({ filter = { installed = true } })
        desc = "选择 CLI",
      },
      {
        "<leader>ad",
        function() require("sidekick.cli").close() end,
        desc = "分离 CLI 会话",
      },
      {
        "<leader>at",
        function() require("sidekick.cli").send({ msg = "{this}" }) end,
        mode = { "x", "n" },
        desc = "发送此内容",
      },
      {
        "<leader>af",
        function() require("sidekick.cli").send({ msg = "{file}" }) end,
        desc = "发送文件",
      },
      {
        "<leader>av",
        function() require("sidekick.cli").send({ msg = "{selection}" }) end,
        mode = { "x" },
        desc = "发送可视区域选区",
      },
      {
        "<leader>ap",
        function() require("sidekick.cli").prompt() end,
        mode = { "n", "x" },
        desc = "Sidekick 选择提示词",
      },
    },
  },

  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      picker = {
        actions = {
          sidekick_send = function(...)
            return require("sidekick.cli.picker.snacks").send(...)
          end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = {
                "sidekick_send",
                mode = { "n", "i" },
              },
            },
          },
        },
      },
    },
  },
}
