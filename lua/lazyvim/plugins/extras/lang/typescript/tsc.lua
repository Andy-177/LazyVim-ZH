return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
      },
      root = { "tsconfig.json", "package.json", "jsconfig.json" },
    })
  end,

  -- 正确配置 lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- 确保 mason 安装该服务器
      servers = {
        tsgo = { enabled = false },
        tsc = {
          -- 显式添加默认文件类型，以便可以在相关的 extra 中
          -- 中继续扩展
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          ---@type lspconfig.settings.tsc
          settings = {
            ["js/ts"] = {
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = false },
                parameterNames = {
                  enabled = "literals",
                  suppressWhenArgumentMatchesName = true,
                },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
        },
      },
    },
  },
  -- 正确配置 lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {},
  },
}
