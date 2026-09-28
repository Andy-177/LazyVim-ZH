return {

  -- 使用 cmdpreview 重命名
  recommended = true,
  desc = "基于 Neovim 命令预览功能的增量式 LSP 重命名",
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {},
  },

  -- LSP 键位
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            {
              "<leader>cr",
              function()
                local inc_rename = require("inc_rename")
                return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
              end,
              expr = true,
              desc = "重命名 (inc-rename.nvim)",
              has = "rename",
            },
          },
        },
      },
    },
  },

  --- Noice 集成
  {
    "folke/noice.nvim",
    optional = true,
    opts = {
      presets = { inc_rename = true },
    },
  },
}
