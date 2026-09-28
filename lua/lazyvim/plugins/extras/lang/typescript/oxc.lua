local supported = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "json",
  "jsonc",
  "vue",
  "svelte",
  "astro",
}

return {
  recommended = function()
    return LazyVim.extras.wants({
      root = {
        ".oxlintrc.json",
        ".oxlintrc.jsonc",
        "oxlint.config.ts",
        ".oxfmtrc.json",
        ".oxfmtrc.jsonc",
        "oxfmt.config.ts",
      },
    })
  end,

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ---@type lspconfig.settings.oxlint
        oxlint = {
          -- capabilities = { textDocument = { diagnostic = vim.NIL } },
          root_dir = function(bufnr, on_dir)
            -- 如果存在顶层 oxlint 配置则优先使用（支持 monorepo）
            local git = vim.fs.root(bufnr, ".git")
            local markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }
            local root = git and vim.fs.root(git, markers) or vim.fs.root(bufnr, markers)
            if root then
              on_dir(root)
            end
          end,
          settings = {
            fixKind = "all",
            -- run = "onType",
          },
        },
        --- 由于使用 conform 进行格式化，禁用 oxfmt lsp 服务器
        oxfmt = { enabled = false },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "oxfmt" } },
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(supported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "oxfmt")
      end
    end,
  },
}
