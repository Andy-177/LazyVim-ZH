return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "yaml",
    })
  end,

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
        yamlls = {
          -- 必须添加此项，yamlls 才知道我们支持行折叠
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },
          -- 在需要时懒加载 schemastore
          before_init = function(_, new_config)
            new_config.settings.yaml.schemas = vim.tbl_deep_extend(
              "force",
              new_config.settings.yaml.schemas or {},
              require("schemastore").yaml.schemas()
            )
          end,
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              keyOrdering = false,
              format = {
                enable = true,
              },
              validate = true,
              schemaStore = {
                -- 必须禁用内置的 schemaStore 支持，才能使用
                -- SchemaStore.nvim 插件提供的 schema
                enable = false,
                -- 避免 TypeError: Cannot read properties of undefined (reading 'length')
                url = "",
              },
            },
          },
        },
      },
    },
  },
}
