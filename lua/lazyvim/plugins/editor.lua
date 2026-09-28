return {

  -- 在多个文件中搜索/替换
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = { "GrugFar", "GrugFarWithin" },
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "x" },
        desc = "搜索并替换",
      },
    },
  },

  -- Flash 通过在每个匹配项末尾显示标签来增强内置搜索功能，
  -- 让你可以快速跳转到特定位置。
  -- （location 指目标位置。）
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    vscode = true,
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash 语法树" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "远程 Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "语法树搜索" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "切换 Flash 搜索" },
      -- 模拟 nvim-treesitter 的增量选择
      { "<c-space>", mode = { "n", "o", "x" },
        function()
          require("flash").treesitter({
            actions = {
              ["<c-space>"] = "next",
              ["<BS>"] = "prev"
            }
          }) 
        end, desc = "语法树增量选择" },
    },
  },

  -- which-key 通过弹出窗口帮助你记住键位绑定，
  -- 窗口中会显示你正在输入的命令所对应的可用键位。
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
    opts = {
      preset = "helix",
      defaults = {},
      spec = {
        {
          mode = { "n", "x" },
          { "<leader><tab>", group = "标签页" },
          { "<leader>c", group = "代码" },
          { "<leader>d", group = "调试" },
          { "<leader>dp", group = "性能分析" },
          { "<leader>f", group = "文件/查找" },
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "变更块" },
          { "<leader>q", group = "退出/会话" },
          { "<leader>s", group = "搜索" },
          { "<leader>u", group = "界面" },
          { "<leader>x", group = "诊断/快速修复" },
          { "[", group = "上一个" },
          { "]", group = "下一个" },
          { "g", group = "跳转" },
          { "gs", group = "环绕操作" },
          { "z", group = "折叠" },
          {
            "<leader>b",
            group = "缓冲区",
            expand = function()
              return require("which-key.extras").expand.buf()
            end,
          },
          {
            "<leader>w",
            group = "窗口",
            proxy = "<c-w>",
            expand = function()
              return require("which-key.extras").expand.win()
            end,
          },
          -- 更友好的描述
          { "gx", desc = "使用系统应用打开" },
        },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "缓冲区键位（which-key）",
      },
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "窗口氢键模式（which-key）",
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      if not vim.tbl_isempty(opts.defaults) then
        LazyVim.warn("which-key：opts.defaults 已废弃，请改用 opts.spec。")
        wk.register(opts.defaults)
      end
    end,
  },

  -- gitsigns 会高亮自上次提交列表以来发生变化的文本，
  -- 提交之后的改动，并允许你交互式地暂存/取消暂存
  -- 提交中的各个变更块。
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
        end

        -- stylua: ignore start
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "下一个变更块")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "上一个变更块")
        map("n", "]H", function() gs.nav_hunk("last") end, "最后一个变更块")
        map("n", "[H", function() gs.nav_hunk("first") end, "第一个变更块")
        map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "暂存变更块")
        map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "撤销变更块暂存")
        map("n", "<leader>ghS", gs.stage_buffer, "暂存缓冲区")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "取消变更块暂存")
        map("n", "<leader>ghR", gs.reset_buffer, "重置缓冲区暂存")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "内联预览变更块")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "逐行溯源")
        map("n", "<leader>ghB", function() gs.blame() end, "缓冲区溯源")
        map("n", "<leader>ghd", gs.diffthis, "与 Git 比较")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "与 Git~ 比较")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "选择变更块")
      end,
    },
  },
  {
    "gitsigns.nvim",
    opts = function()
      Snacks.toggle({
        name = "Git 变更标记",
        get = function()
          return require("gitsigns.config").config.signcolumn
        end,
        set = function(state)
          require("gitsigns").toggle_signs(state)
        end,
      }):map("<leader>uG")
    end,
  },

  -- 更好的诊断列表及其它功能
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "诊断（Trouble）" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "缓冲区诊断（Trouble）" },
      { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "符号（Trouble）" },
      { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP 引用/定义/……（Trouble）" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "位置列表（Trouble）" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "快速修复列表（Trouble）" },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "上一个 Trouble/快速修复项",
      },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "下一个 Trouble/快速修复项",
      },
    },
  },

  -- 查找并列出项目中所有 TODO、HACK、BUG 等注释，
  -- 并加载到一个可浏览的列表中。
  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble", "TodoTelescope" },
    event = "LazyFile",
    opts = {},
    -- stylua: ignore
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "下一条待办注释" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "上一条待办注释" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "待办（Trouble）" },
      { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "待办/修复（Trouble）" },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "待办" },
      { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "待办/修复" },
    },
  },
}
