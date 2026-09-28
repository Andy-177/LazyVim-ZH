if lazyvim_docs then
  -- 用于 Ruby 的 LSP 服务器。
  -- 设为 "solargraph" 可使用 solargraph 代替 ruby_lsp。
  vim.g.lazyvim_ruby_lsp = "ruby_lsp"
  vim.g.lazyvim_ruby_formatter = "rubocop"
end

local lsp = vim.g.lazyvim_ruby_lsp or "ruby_lsp"
local formatter = vim.g.lazyvim_ruby_formatter or "rubocop"

return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "ruby",
      root = "Gemfile",
    })
  end,
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "ruby" } },
  },
  {
    "neovim/nvim-lspconfig",
    ---@type PluginLspOpts
    opts = {
      servers = {
        ruby_lsp = {
          enabled = lsp == "ruby_lsp",
        },
        solargraph = {
          enabled = lsp == "solargraph",
        },
        rubocop = {
          -- 如果 Solargraph 和 Rubocop 都作为 LSP 启用，
          -- 诊断会重复，因为 Solargraph 在安装了 Rubocop 时
          -- 已经会调用 Rubocop
          enabled = formatter == "rubocop" and lsp ~= "solargraph",
        },
        standardrb = {
          enabled = formatter == "standardrb",
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "erb-formatter", "erb-lint" } },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "suketa/nvim-dap-ruby",
      config = function()
        require("dap-ruby").setup()
      end,
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ruby = { formatter },
        eruby = { "erb_format" },
      },
    },
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "olimorris/neotest-rspec",
    },
    opts = {
      adapters = {
        ["neotest-rspec"] = {
          -- 注意：默认情况下 neotest-rspec 使用系统全局的 rspec gem，而不是通过 bundler 提供的那个
          -- rspec_cmd = function()
          --   return vim.tbl_flatten({
          --     "bundle",
          --     "exec",
          --     "rspec",
          --   })
          -- end,
        },
      },
    },
  },
}
