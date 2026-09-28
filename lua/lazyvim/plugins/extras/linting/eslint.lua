if lazyvim_docs then
  -- 设为 false 可禁用自动格式化
  vim.g.lazyvim_eslint_auto_format = true
end

local auto_format = vim.g.lazyvim_eslint_auto_format == nil or vim.g.lazyvim_eslint_auto_format

return {
  {
    "neovim/nvim-lspconfig",
    -- 其它设置出于简洁已省略
    opts = {
      ---@type table<string, vim.lsp.Config>
      servers = {
        eslint = {
          settings = {
            -- 当 eslintrc 位于子文件夹而非 cwd 根目录时，帮助 eslint 找到它
            workingDirectories = { mode = "auto" },
            format = auto_format,
          },
        },
      },
      setup = {
        eslint = function()
          if not auto_format then
            return
          end

          local formatter = LazyVim.lsp.formatter({
            name = "eslint: lsp",
            primary = false,
            priority = 200,
            filter = "eslint",
          })

          -- 向 LazyVim 注册格式化程序
          LazyVim.format.register(formatter)
        end,
      },
    },
  },
}
