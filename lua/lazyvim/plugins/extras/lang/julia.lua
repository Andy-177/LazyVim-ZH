return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = { "julia" },
      root = { "Project.toml" },
    })
  end,

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "julia" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        julials = {
          settings = {
            -- 使用与 Julia VS Code 扩展相同的默认设置
            julia = {
              completionmode = "qualify",
              lint = { missingrefs = "none" },
            },
          },
        },
      },
    },
  },

  -- cmp 集成
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = { "kdheepak/cmp-latex-symbols" },
    opts = function(_, opts)
      table.insert(opts.sources, {
        name = "latex_symbols",
        option = {
          strategy = 0, -- mixed
        },
      })
    end,
  },

  -- blink.cmp 集成
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "kdheepak/cmp-latex-symbols", "saghen/blink.compat" },
    opts = {
      sources = {
        compat = { "latex_symbols" },
        providers = {
          latex_symbols = {
            kind = "LatexSymbols",
            async = true,
            opts = {
              strategy = 0, -- mixed
            },
          },
        },
      },
    },
  },
}
