return {
  -- 活动的缩进参考线和缩进文本对象。当你在浏览
  -- 代码时，它会高亮当前的缩进级别，并让高亮
  -- 带动画效果。
  {
    "nvim-mini/mini.indentscope",
    version = false, -- wait till new 0.7.0 release to put it back on semver
    event = "LazyFile",
    opts = {
      -- symbol = "▏",
      symbol = "│",
      options = { try_as_border = true },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "Trouble",
          "alpha",
          "dashboard",
          "fzf",
          "help",
          "lazy",
          "mason",
          "neo-tree",
          "notify",
          "sidekick_terminal",
          "snacks_dashboard",
          "snacks_notif",
          "snacks_terminal",
          "snacks_win",
          "toggleterm",
          "trouble",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "SnacksDashboardOpened",
        callback = function(data)
          vim.b[data.buf].miniindentscope_disable = true
        end,
      })
    end,
  },

  -- 启用 mini-indentscope 时禁用 indent-blankline 的 scope
  {
    "lukas-reineke/indent-blankline.nvim",
    optional = true,
    event = "LazyFile",
    opts = {
      scope = { enabled = false },
    },
  },

  -- 启用 mini-indentscope 时禁用 snacks scope
  {
    "snacks.nvim",
    opts = {
      indent = {
        scope = { enabled = false },
      },
    },
  },
}
