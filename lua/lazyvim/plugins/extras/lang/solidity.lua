return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "solidity",
      root = {
        "foundry.toml",
        "hardhat.config.js",
        "hardhat.config.ts",
      },
    })
  end,
  -- 将 Solidity 及相关内容添加到 treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "solidity" } },
  },

  -- 正确配置 Solidity 的 lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solidity_ls = {},
      },
    },
  },
  -- Solidity 的格式化工具
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        solidity = { "forge_fmt" },
      },
    },
  },
}
