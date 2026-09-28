return {

  -- 确保已安装 GitUI 工具
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "gitui" } },
    keys = {
      {
        "<leader>gG",
        function()
          Snacks.terminal({ "gitui" })
        end,
        desc = "GitUi（当前目录）",
      },
      {
        "<leader>gg",
        function()
          Snacks.terminal({ "gitui" }, { cwd = LazyVim.root.get() })
        end,
        desc = "GitUi（根目录）",
      },
    },
    init = function()
      -- 删除用于文件历史的 lazygit 键位
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimKeymaps",
        once = true,
        callback = function()
          pcall(vim.keymap.del, "n", "<leader>gf")
          pcall(vim.keymap.del, "n", "<leader>gl")
        end,
      })
    end,
  },
}
