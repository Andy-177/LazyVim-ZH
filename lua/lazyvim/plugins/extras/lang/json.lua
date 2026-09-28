return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = { "json", "jsonc", "json5" },
      root = { "*.json" },
    })
  end,

  -- 将 json 添加到 treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "json5" } },
  },

  -- yaml schema 支持
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },

  -- 正确配置 lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- 确保 mason 安装该服务器
      servers = {
        jsonls = {
          -- 在需要时懒加载 schemastore
          before_init = function(_, new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = {
            json = {
              format = {
                enable = true,
              },
              validate = { enable = true },
            },
          },
        },
      },
    },
  },
}
