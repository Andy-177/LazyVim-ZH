if not vim.g.vscode then
  return {}
end

local enabled = {
  "LazyVim",
  "dial.nvim",
  "flit.nvim",
  "lazy.nvim",
  "leap.nvim",
  "mini.ai",
  "mini.comment",
  "mini.move",
  "mini.pairs",
  "mini.surround",
  "nvim-treesitter",
  "nvim-treesitter-textobjects",
  "nvim-ts-context-commentstring",
  "snacks.nvim",
  "ts-comments.nvim",
  "vim-repeat",
  "yanky.nvim",
}

local Config = require("lazy.core.config")
local vscode = require("vscode")
Config.options.checker.enabled = false
Config.options.change_detection.enabled = false
Config.options.defaults.cond = function(plugin)
  return vim.tbl_contains(enabled, plugin.name) or plugin.vscode
end
vim.g.snacks_animate = false

-- 添加一些 vscode 专用的键位
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimKeymapsDefaults",
  callback = function()
    -- 用于搜索和导航的 VSCode 专用键位
    vim.keymap.set("n", "<leader><space>", "<cmd>Find<cr>")
    vim.keymap.set("n", "<leader>/", function()
      vscode.call("workbench.action.findInFiles")
    end)
    vim.keymap.set("n", "<leader>ss", function()
      vscode.call("workbench.action.gotoSymbol")
    end)

    -- 切换 VS Code 集成终端
    for _, lhs in ipairs({ "<leader>ft", "<leader>fT", "<c-/>" }) do
      vim.keymap.set("n", lhs, function()
        vscode.call("workbench.action.terminal.toggleTerminal")
      end)
    end

    -- 像切换 lazyvim 缓冲区一样浏览 VSCode 标签页
    vim.keymap.set("n", "<S-h>", function()
      vscode.call("workbench.action.previousEditor")
    end)
    vim.keymap.set("n", "<S-l>", function()
      vscode.call("workbench.action.nextEditor")
    end)
  end,
})

return {
  {
    "snacks.nvim",
    opts = {
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      indent = { enabled = false },
      input = { enabled = false },
      notifier = { enabled = false },
      picker = { enabled = false },
      quickfile = { enabled = false },
      scroll = { enabled = false },
      statuscolumn = { enabled = false },
    },
  },
  {
    "LazyVim/LazyVim",
    config = function(_, opts)
      opts = opts or {}
      -- 禁用配色方案
      opts.colorscheme = function() end
      require("lazyvim").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { highlight = { enable = false } },
  },
}
