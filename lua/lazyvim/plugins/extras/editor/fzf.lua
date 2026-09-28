if lazyvim_docs then
  -- 如果你不想使用 `:LazyExtras`，
  -- 则需要设置下面的选项。
  vim.g.lazyvim_picker = "fzf"
end

---@class FzfLuaOpts: lazyvim.util.pick.Opts
---@field cmd string?

---@type LazyPicker
local picker = {
  name = "fzf",
  commands = {
    files = "files",
  },

  ---@param command string
  ---@param opts? FzfLuaOpts
  open = function(command, opts)
    opts = opts or {}
    if opts.cmd == nil and command == "git_files" and opts.show_untracked then
      opts.cmd = "git ls-files --exclude-standard --cached --others"
    end
    return require("fzf-lua")[command](opts)
  end,
}
if not LazyVim.pick.register(picker) then
  return {}
end

local function symbols_filter(entry, ctx)
  if ctx.symbols_filter == nil then
    ctx.symbols_filter = LazyVim.config.get_kind_filter(ctx.bufnr) or false
  end
  if ctx.symbols_filter == false then
    return true
  end
  return vim.tbl_contains(ctx.symbols_filter, entry.kind)
end

return {
  desc = "优秀的 FZF 选择器（Telescope 的替代品）",
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = function(_, opts)
      local fzf = require("fzf-lua")
      local config = fzf.config
      local actions = fzf.actions

      -- 快速修复
      config.defaults.keymap.fzf["ctrl-q"] = "select-all+accept"
      config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
      config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
      config.defaults.keymap.fzf["ctrl-x"] = "jump"
      config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
      config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
      config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
      config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"

      -- Trouble
      if LazyVim.has("trouble.nvim") then
        config.defaults.actions.files["ctrl-t"] = require("trouble.sources.fzf").actions.open
      end

      -- 切换根目录 / 当前目录
      config.defaults.actions.files["ctrl-r"] = function(_, ctx)
        local o = vim.deepcopy(ctx.__call_opts)
        o.root = o.root == false
        o.cwd = nil
        o.buf = ctx.__CTX.bufnr
        LazyVim.pick.open(ctx.__INFO.cmd, o)
      end
      config.defaults.actions.files["alt-c"] = config.defaults.actions.files["ctrl-r"]
      config.set_action_helpstr(config.defaults.actions.files["ctrl-r"], "toggle-root-dir")

      local img_previewer ---@type string[]?
      for _, v in ipairs({
        { cmd = "ueberzug", args = {} },
        { cmd = "chafa", args = { "{file}", "--format=symbols" } },
        { cmd = "viu", args = { "-b" } },
      }) do
        if vim.fn.executable(v.cmd) == 1 then
          img_previewer = vim.list_extend({ v.cmd }, v.args)
          break
        end
      end

      return {
        "default-title",
        fzf_colors = true,
        fzf_opts = {
          ["--no-scrollbar"] = true,
        },
        defaults = {
          -- 格式化器
          formatter = "path.dirname_first",
        },
        previewers = {
          builtin = {
            extensions = {
              ["png"] = img_previewer,
              ["jpg"] = img_previewer,
              ["jpeg"] = img_previewer,
              ["gif"] = img_previewer,
              ["webp"] = img_previewer,
            },
            ueberzug_scaler = "fit_contain",
          },
        },
        -- 用于配置 vim.ui.select 的 LazyVim 自定义选项
        ui_select = function(fzf_opts, items)
          return vim.tbl_deep_extend("force", fzf_opts, {
            prompt = " ",
            winopts = {
              title = " " .. vim.trim((fzf_opts.prompt or "选择"):gsub("%s*:%s*$", "")) .. " ",
              title_pos = "center",
            },
          }, fzf_opts.kind == "codeaction" and {
            winopts = {
              layout = "vertical",
              -- 高度为条目数减去用于预览的 15 行，最大为屏幕高度的 80%
              height = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 4) + 0.5) + 16,
              width = 0.5,
              preview = not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = 0, name = "vtsls" })) and {
                layout = "vertical",
                vertical = "down:15,border-top",
                hidden = "hidden",
              } or {
                layout = "vertical",
                vertical = "down:15,border-top",
              },
            },
          } or {
            winopts = {
              width = 0.5,
              -- 高度为条目数，最大为屏幕高度的 80%
              height = math.floor(math.min(vim.o.lines * 0.8, #items + 4) + 0.5),
            },
          })
        end,
        winopts = {
          width = 0.8,
          height = 0.8,
          row = 0.5,
          col = 0.5,
          preview = {
            scrollchars = { "┃", "" },
          },
        },
        files = {
          cwd_prompt = false,
          actions = {
            ["alt-i"] = { actions.toggle_ignore },
            ["alt-h"] = { actions.toggle_hidden },
          },
        },
        grep = {
          actions = {
            ["alt-i"] = { actions.toggle_ignore },
            ["alt-h"] = { actions.toggle_hidden },
          },
        },
        lsp = {
          symbols = {
            symbol_hl = function(s)
              return "TroubleIcon" .. s
            end,
            symbol_fmt = function(s)
              return s:lower() .. "\t"
            end,
            child_prefix = false,
          },
          code_actions = {
            previewer = vim.fn.executable("delta") == 1 and "codeaction_native" or nil,
          },
        },
      }
    end,
    config = function(_, opts)
      if opts[1] == "default-title" then
        -- 对于 profile `default-title` 以及以 `default-title` 为基础 profile 的
        -- 配置，为所有选择器使用相同的提示符
        local function fix(t)
          t.prompt = t.prompt ~= nil and " " or nil
          for _, v in pairs(t) do
            if type(v) == "table" then
              fix(v)
            end
          end
          return t
        end
        opts = vim.tbl_deep_extend("force", fix(require("fzf-lua.profiles.default-title")), opts)
        opts[1] = nil
      end
      require("fzf-lua").setup(opts)
    end,
    init = function()
      LazyVim.on_very_lazy(function()
        vim.ui.select = function(...)
          require("lazy").load({ plugins = { "fzf-lua" } })
          local opts = LazyVim.opts("fzf-lua") or {}
          require("fzf-lua").register_ui_select(opts.ui_select or nil)
          return vim.ui.select(...)
        end
      end)
    end,
    keys = {
      { "<c-j>", "<c-j>", ft = "fzf", mode = "t", nowait = true },
      { "<c-k>", "<c-k>", ft = "fzf", mode = "t", nowait = true },
      {
        "<leader>,",
        "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>",
        desc = "切换缓冲区",
      },
      { "<leader>/", LazyVim.pick("live_grep"), desc = "搜索文本（根目录）" },
      { "<leader>:", "<cmd>FzfLua command_history<cr>", desc = "命令历史" },
      { "<leader><space>", LazyVim.pick("files"), desc = "查找文件（根目录）" },
      -- 查找
      { "<leader>fb", "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "缓冲区" },
      { "<leader>fB", "<cmd>FzfLua buffers<cr>", desc = "缓冲区（全部）" },
      { "<leader>fc", LazyVim.pick.config_files(), desc = "查找配置文件" },
      { "<leader>ff", LazyVim.pick("files"), desc = "查找文件（根目录）" },
      { "<leader>fF", LazyVim.pick("files", { root = false }), desc = "查找文件（cwd）" },
      { "<leader>fg", "<cmd>FzfLua git_files<cr>", desc = "查找文件（git-files）" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "最近" },
      { "<leader>fR", LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "最近（cwd）" },
      -- git
      { "<leader>gc", "<cmd>FzfLua git_commits<CR>", desc = "提交记录" },
      { "<leader>gd", "<cmd>FzfLua git_diff<cr>", desc = "Git 差异（文件）" },
      { "<leader>gl", "<cmd>FzfLua git_commits<CR>", desc = "提交记录" },
      { "<leader>gs", "<cmd>FzfLua git_status<CR>", desc = "状态" },
      { "<leader>gS", "<cmd>FzfLua git_stash<cr>", desc = "Git 储藏" },
      -- 搜索
      { '<leader>s"', "<cmd>FzfLua registers<cr>", desc = "寄存器" },
      { "<leader>s/", "<cmd>FzfLua search_history<cr>", desc = "搜索历史" },
      { "<leader>sa", "<cmd>FzfLua autocmds<cr>", desc = "自动命令" },
      { "<leader>sb", "<cmd>FzfLua lines<cr>", desc = "缓冲区行" },
      { "<leader>sc", "<cmd>FzfLua command_history<cr>", desc = "命令历史" },
      { "<leader>sC", "<cmd>FzfLua commands<cr>", desc = "命令" },
      { "<leader>sd", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "诊断" },
      { "<leader>sD", "<cmd>FzfLua diagnostics_document<cr>", desc = "缓冲区诊断" },
      { "<leader>sg", LazyVim.pick("live_grep"), desc = "搜索文本（根目录）" },
      { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "搜索文本（cwd）" },
      { "<leader>sh", "<cmd>FzfLua help_tags<cr>", desc = "帮助页面" },
      { "<leader>sH", "<cmd>FzfLua highlights<cr>", desc = "搜索高亮组" },
      { "<leader>sj", "<cmd>FzfLua jumps<cr>", desc = "跳转列表" },
      { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "键位映射" },
      { "<leader>sl", "<cmd>FzfLua loclist<cr>", desc = "位置列表" },
      { "<leader>sM", "<cmd>FzfLua man_pages<cr>", desc = "Man 页面" },
      { "<leader>sm", "<cmd>FzfLua marks<cr>", desc = "跳到标记" },
      { "<leader>sR", "<cmd>FzfLua resume<cr>", desc = "继续上次选择" },
      { "<leader>sq", "<cmd>FzfLua quickfix<cr>", desc = "快速修复列表" },
      { "<leader>sw", LazyVim.pick("grep_cword"), desc = "单词（根目录）" },
      { "<leader>sW", LazyVim.pick("grep_cword", { root = false }), desc = "单词（cwd）" },
      { "<leader>sw", LazyVim.pick("grep_visual"), mode = "x", desc = "可视区域（根目录）" },
      { "<leader>sW", LazyVim.pick("grep_visual", { root = false }), mode = "x", desc = "可视区域（cwd）" },
      { "<leader>uC", LazyVim.pick("colorschemes"), desc = "配色方案（带预览）" },
      {
        "<leader>ss",
        function()
          require("fzf-lua").lsp_document_symbols({
            regex_filter = symbols_filter,
          })
        end,
        desc = "转到符号",
      },
      {
        "<leader>sS",
        function()
          require("fzf-lua").lsp_live_workspace_symbols({
            regex_filter = symbols_filter,
          })
        end,
        desc = "转到符号（工作区）",
      },
    },
  },

  {
    "folke/todo-comments.nvim",
    optional = true,
    -- stylua: ignore
    keys = {
      { "<leader>st", function() require("todo-comments.fzf").todo() end, desc = "待办事项" },
      { "<leader>sT", function () require("todo-comments.fzf").todo({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "待办/修复/待修复" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- stylua: ignore
        ["*"] = {
          keys = {
            { "gd", "<cmd>FzfLua lsp_definitions     jump1=true ignore_current_line=true<cr>", desc = "转到定义", has = "definition" },
            { "gr", "<cmd>FzfLua lsp_references      jump1=true ignore_current_line=true<cr>", desc = "引用", nowait = true },
            { "gI", "<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>", desc = "转到实现" },
            { "gy", "<cmd>FzfLua lsp_typedefs        jump1=true ignore_current_line=true<cr>", desc = "转到类[y]型定义" },
          }
        },
      },
    },
  },
}
