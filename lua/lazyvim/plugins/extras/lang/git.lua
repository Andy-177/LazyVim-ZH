return {
  recommended = {
    ft = { "gitcommit", "gitconfig", "gitrebase", "gitignore", "gitattributes" },
  },
  -- Treesitter 的 git 支持
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "git_config", "gitcommit", "git_rebase", "gitignore", "gitattributes" } },
  },

  {
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = {
      { "petertriho/cmp-git", opts = {} },
    },
    ---@module 'cmp'
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "git" })
    end,
  },
}
