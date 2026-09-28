if lazyvim_docs then
  -- 如果你不想使用 `:LazyExtras`，
  -- 则需要设置下面的选项。
  vim.g.lazyvim_picker = "telescope"
end

local build_cmd ---@type string?
for _, cmd in ipairs({ "make", "cmake", "gmake" }) do
  if vim.fn.executable(cmd) == 1 then
    build_cmd = cmd
    break
  end
end

---@type LazyPicker
local picker = {
  name = "telescope",
  commands = {
    files = "find_files",
  },
  -- 这会返回一个调用 telescope 的函数。
  -- cwd 默认为 lazyvim.util.get_root
  -- 对于 `files`，会根据是否存在 .git 选择 git_files 或 find_files
  ---@param builtin string
  ---@param opts? lazyvim.util.pick.Opts
  open = function(builtin, opts)
    opts = opts or {}
    opts.follow = opts.follow ~= false
    if opts.cwd and opts.cwd ~= vim.uv.cwd() then
      local function open_cwd_dir()
        local action_state = require("telescope.actions.state")
        local line = action_state.get_current_line()
        LazyVim.pick.open(
          builtin,
          vim.tbl_deep_extend("force", {}, opts or {}, {
            root = false,
            default_text = line,
          })
        )
      end
      ---@diagnostic disable-next-line: inject-field
      opts.attach_mappings = function(_, map)
        -- opts.desc 会被 telescope 覆盖，在其修复之前先这样处理
        map("i", "<a-c>", open_cwd_dir, { desc = "打开当前目录" })
        return true
      end
    end

    require("telescope.builtin")[builtin](opts)
  end,
}
if not LazyVim.pick.register(picker) then
  return {}
end

return {
  -- 模糊查找器。
  -- 查找文件的默认键位会根据当前目录是否为 git 仓库，
  -- 使用 Telescope 的 `find_files` 或 `git_files`。
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false, -- telescope did only one release, so use HEAD for now
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = (build_cmd ~= "cmake") and "make"
          or "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
        enabled = build_cmd ~= nil,
        config = function(plugin)
          LazyVim.on_load("telescope.nvim", function()
            local ok, err = pcall(require("telescope").load_extension, "fzf")
            if not ok then
              local lib = plugin.dir .. "/build/libfzf." .. (LazyVim.is_win() and "dll" or "so")
              if not vim.uv.fs_stat(lib) then
                LazyVim.warn("`telescope-fzf-native.nvim` 尚未构建，正在重新构建……")
                require("lazy").build({ plugins = { plugin }, show = false }):wait(function()
                  LazyVim.info("`telescope-fzf-native.nvim` 重新构建完成。\n请重启 Neovim。")
                end)
              else
                LazyVim.error("加载 `telescope-fzf-native.nvim` 失败：\n" .. err)
              end
            end
          end)
        end,
      },
    },
    keys = {
      {
        "<leader>,",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
        desc = "切换缓冲区",
      },
      { "<leader>/", LazyVim.pick("live_grep"), desc = "搜索文本（根目录）" },
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "命令历史" },
      { "<leader><space>", LazyVim.pick("files"), desc = "查找文件（根目录）" },
      -- 查找
      {
        "<leader>fb",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>",
        desc = "缓冲区",
      },
      { "<leader>fB", "<cmd>Telescope buffers<cr>", desc = "缓冲区（全部）" },
      { "<leader>fc", LazyVim.pick.config_files(), desc = "查找配置文件" },
      { "<leader>ff", LazyVim.pick("files"), desc = "查找文件（根目录）" },
      { "<leader>fF", LazyVim.pick("files", { root = false }), desc = "查找文件（cwd）" },
      { "<leader>fg", "<cmd>Telescope git_files<cr>", desc = "查找文件（git-files）" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "最近" },
      { "<leader>fR", LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "最近（cwd）" },
      -- git
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "提交记录" },
      { "<leader>gl", "<cmd>Telescope git_commits<CR>", desc = "提交记录" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "状态" },
      { "<leader>gS", "<cmd>Telescope git_stash<cr>", desc = "Git 储藏" },
      -- 搜索
      { '<leader>s"', "<cmd>Telescope registers<cr>", desc = "寄存器" },
      { "<leader>s/", "<cmd>Telescope search_history<cr>", desc = "搜索历史" },
      { "<leader>sa", "<cmd>Telescope autocommands<cr>", desc = "自动命令" },
      { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "缓冲区行" },
      { "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "命令历史" },
      { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "命令" },
      { "<leader>sd", "<cmd>Telescope diagnostics<cr>", desc = "诊断" },
      { "<leader>sD", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "缓冲区诊断" },
      { "<leader>sg", LazyVim.pick("live_grep"), desc = "搜索文本（根目录）" },
      { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "搜索文本（cwd）" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "帮助页面" },
      { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "搜索高亮组" },
      { "<leader>sj", "<cmd>Telescope jumplist<cr>", desc = "跳转列表" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "键位映射" },
      { "<leader>sl", "<cmd>Telescope loclist<cr>", desc = "位置列表" },
      { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man 页面" },
      { "<leader>sm", "<cmd>Telescope marks<cr>", desc = "跳到标记" },
      { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "选项" },
      { "<leader>sR", "<cmd>Telescope resume<cr>", desc = "继续上次选择" },
      { "<leader>sq", "<cmd>Telescope quickfix<cr>", desc = "快速修复列表" },
      { "<leader>sw", LazyVim.pick("grep_string", { word_match = "-w" }), desc = "单词（根目录）" },
      { "<leader>sW", LazyVim.pick("grep_string", { root = false, word_match = "-w" }), desc = "单词（cwd）" },
      { "<leader>sw", LazyVim.pick("grep_string"), mode = "x", desc = "可视区域（根目录）" },
      { "<leader>sW", LazyVim.pick("grep_string", { root = false }), mode = "x", desc = "可视区域（cwd）" },
      { "<leader>uC", LazyVim.pick("colorscheme", { enable_preview = true }), desc = "配色方案（带预览）" },
      {
        "<leader>ss",
        function()
          require("telescope.builtin").lsp_document_symbols({
            symbols = LazyVim.config.get_kind_filter(),
          })
        end,
        desc = "转到符号",
      },
      {
        "<leader>sS",
        function()
          require("telescope.builtin").lsp_dynamic_workspace_symbols({
            symbols = LazyVim.config.get_kind_filter(),
          })
        end,
        desc = "转到符号（工作区）",
      },
    },
    opts = function()
      local actions = require("telescope.actions")

      local open_with_trouble = function(...)
        return require("trouble.sources.telescope").open(...)
      end
      local find_files_no_ignore = function()
        local action_state = require("telescope.actions.state")
        local line = action_state.get_current_line()
        LazyVim.pick("find_files", { no_ignore = true, default_text = line })()
      end
      local find_files_with_hidden = function()
        local action_state = require("telescope.actions.state")
        local line = action_state.get_current_line()
        LazyVim.pick("find_files", { hidden = true, default_text = line })()
      end

      local function find_command()
        if 1 == vim.fn.executable("rg") then
          return { "rg", "--files", "--color", "never", "-g", "!.git" }
        elseif 1 == vim.fn.executable("fd") then
          return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
        elseif 1 == vim.fn.executable("fdfind") then
          return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
        elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
          return { "find", ".", "-type", "f" }
        elseif 1 == vim.fn.executable("where") then
          return { "where", "/r", ".", "*" }
        end
      end

      return {
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          -- 在第一个存放实际文件的窗口中打开文件。
          -- 如果没有其他可用窗口，则使用当前窗口。
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == "" then
                return win
              end
            end
            return 0
          end,
          mappings = {
            i = {
              ["<c-t>"] = open_with_trouble,
              ["<a-t>"] = open_with_trouble,
              ["<a-i>"] = find_files_no_ignore,
              ["<a-h>"] = find_files_with_hidden,
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
            },
            n = {
              ["q"] = actions.close,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = find_command,
            hidden = true,
          },
        },
      }
    end,
  },

  -- Flash Telescope 配置
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    opts = function(_, opts)
      if not LazyVim.has("flash.nvim") then
        return
      end
      local function flash(prompt_bufnr)
        require("flash").jump({
          pattern = "^",
          label = { after = { 0, 0 } },
          search = {
            mode = "search",
            exclude = {
              function(win)
                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
              end,
            },
          },
          action = function(match)
            local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        })
      end
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        mappings = { n = { s = flash }, i = { ["<c-s>"] = flash } },
      })
    end,
  },

  -- 用 telescope 增强 vim.ui
  {
    "stevearc/dressing.nvim",
    lazy = true,
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          -- stylua: ignore
          keys = {
            { "gd", function() require("telescope.builtin").lsp_definitions({ reuse_win = true }) end, desc = "转到定义", has = "definition" },
            { "gr", "<cmd>Telescope lsp_references<cr>", desc = "引用", nowait = true },
            { "gI", function() require("telescope.builtin").lsp_implementations({ reuse_win = true }) end, desc = "转到实现" },
            { "gy", function() require("telescope.builtin").lsp_type_definitions({ reuse_win = true }) end, desc = "转到类[y]型定义" },
          },
        },
      },
    },
  },
}
