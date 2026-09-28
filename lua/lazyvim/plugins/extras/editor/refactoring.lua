if LazyVim.has_extra("editor.refactoring") then
  if vim.fn.has("nvim-0.12") == 0 then
    LazyVim.error("refactoring.nvim 需要 Neovim 0.12 或更高版本", { title = "refactoring.nvim" })
    return {}
  end
end

return {
  { "lewis6991/async.nvim", lazy = true },

  {
    "ThePrimeagen/refactoring.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<leader>r", "", desc = "+refactor", mode = { "n", "x" } },
      {
        "<leader>rs",
        function()
          return require("refactoring").select_refactor()
        end,
        mode = { "n", "x" },
        desc = "选择重构操作",
      },
      {
        "<leader>ri",
        function()
          return require("refactoring").inline_var()
        end,
        mode = { "n", "x" },
        desc = "内联变量",
        expr = true,
      },
      {
        "<leader>rP",
        function()
          return require("refactoring.debug").print_loc({ output_location = "below" })
        end,
        desc = "调试打印位置",
        expr = true,
      },
      {
        "<leader>rp",
        function()
          return require("refactoring.debug").print_var({ output_location = "below" }) .. "iw"
        end,
        mode = { "n", "x" },
        desc = "调试打印变量",
        expr = true,
      },
      {
        "<leader>rc",
        function()
          return require("refactoring.debug").cleanup({ restore_view = true }) .. "ag"
        end,
        desc = "调试清理",
        expr = true,
      },
      {
        "<leader>rf",
        function()
          return require("refactoring").extract_func()
        end,
        mode = { "n", "x" },
        desc = "提取函数",
        expr = true,
      },
      {
        "<leader>rF",
        function()
          return require("refactoring").extract_func_to_file()
        end,
        mode = { "n", "x" },
        desc = "提取函数到文件",
        expr = true,
      },
      {
        "<leader>rx",
        function()
          return require("refactoring").extract_var()
        end,
        mode = { "n", "x" },
        desc = "提取变量",
        expr = true,
      },
    },
    opts = {},
  },
}
