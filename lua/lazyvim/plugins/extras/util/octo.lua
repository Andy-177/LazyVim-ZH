return {

  -- 依赖 git 扩展来高亮和自动补全 github 的 issue/pr
  { import = "lazyvim.plugins.extras.lang.git" },

  {
    "folke/snacks.nvim",
    keys = { -- disable conflicting keymaps
      { "<leader>gi", false },
      { "<leader>gI", false },
      { "<leader>gp", false },
      { "<leader>gP", false },
    },
  },

  -- Octo
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    event = { { event = "BufReadCmd", pattern = "octo://*" } },
    opts = {
      enable_builtin = true,
      default_to_projects_v2 = true,
      default_merge_method = "squash",
      picker = "telescope",
    },
    keys = {
      { "<leader>gi", "<cmd>Octo issue list<CR>", desc = "列出 Issue (Octo)" },
      { "<leader>gI", "<cmd>Octo issue search<CR>", desc = "搜索 Issue (Octo)" },
      { "<leader>gp", "<cmd>Octo pr list<CR>", desc = "列出 PR (Octo)" },
      { "<leader>gP", "<cmd>Octo pr search<CR>", desc = "搜索 PR (Octo)" },
      { "<leader>gr", "<cmd>Octo repo list<CR>", desc = "列出仓库 (Octo)" },
      { "<leader>gS", "<cmd>Octo search<CR>", desc = "搜索 (Octo)" },

      { "<localleader>a", "", desc = "+assignee (Octo)", ft = "octo" },
      { "<localleader>c", "", desc = "+comment/code (Octo)", ft = "octo" },
      { "<localleader>l", "", desc = "+label (Octo)", ft = "octo" },
      { "<localleader>i", "", desc = "+issue (Octo)", ft = "octo" },
      { "<localleader>r", "", desc = "+react (Octo)", ft = "octo" },
      { "<localleader>p", "", desc = "+pr (Octo)", ft = "octo" },
      { "<localleader>pr", "", desc = "+rebase (Octo)", ft = "octo" },
      { "<localleader>ps", "", desc = "+squash (Octo)", ft = "octo" },
      { "<localleader>v", "", desc = "+review (Octo)", ft = "octo" },
      { "<localleader>g", "", desc = "+goto_issue (Octo)", ft = "octo" },
      { "@", "@<C-x><C-o>", mode = "i", ft = "octo", silent = true },
      { "#", "#<C-x><C-o>", mode = "i", ft = "octo", silent = true },
    },
  },

  -- Octo 选择器
  {
    "pwntester/octo.nvim",
    opts = function(_, opts)
      vim.treesitter.language.register("markdown", "octo")
      if LazyVim.has_extra("editor.telescope") then
        opts.picker = "telescope"
      elseif LazyVim.has_extra("editor.fzf") then
        opts.picker = "fzf-lua"
      elseif LazyVim.has_extra("editor.snacks_picker") then
        opts.picker = "snacks"
      else
        LazyVim.error("`octo.nvim` 需要 `telescope.nvim`、`fzf-lua` 或 `snacks.nvim`")
      end

      -- 在会话中保留一些空窗口
      vim.api.nvim_create_autocmd("ExitPre", {
        group = vim.api.nvim_create_augroup("octo_exit_pre", { clear = true }),
        callback = function(ev)
          local keep = { "octo" }
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.tbl_contains(keep, vim.bo[buf].filetype) then
              vim.bo[buf].buftype = "" -- set buftype to empty to keep the window
            end
          end
        end,
      })
    end,
  },
}
