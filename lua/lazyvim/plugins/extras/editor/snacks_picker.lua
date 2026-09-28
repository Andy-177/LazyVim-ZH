if lazyvim_docs then
  -- 如果你不想使用 `:LazyExtras`，
  -- 则需要设置下面的选项。
  vim.g.lazyvim_picker = "snacks"
end

---@module 'snacks'

---@type LazyPicker
local picker = {
  name = "snacks",
  commands = {
    files = "files",
    live_grep = "grep",
    oldfiles = "recent",
  },

  ---@param source string
  ---@param opts? snacks.picker.Config
  open = function(source, opts)
    return Snacks.picker.pick(source, opts)
  end,
}
if not LazyVim.pick.register(picker) then
  return {}
end

return {
  desc = "快速且现代的文件选择器",
  recommended = true,
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        win = {
          input = {
            keys = {
              ["<a-c>"] = {
                "toggle_cwd",
                mode = { "n", "i" },
              },
            },
          },
        },
        actions = {
          ---@param p snacks.Picker
          toggle_cwd = function(p)
            local root = LazyVim.root({ buf = p.input.filter.current_buf, normalize = true })
            local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
            local current = p:cwd()
            p:set_cwd(current == root and cwd or root)
            p:find()
          end,
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "缓冲区" },
      { "<leader>/", LazyVim.pick("grep"), desc = "搜索文本（根目录）" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "命令历史" },
      { "<leader><space>", LazyVim.pick("files"), desc = "查找文件（根目录）" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "通知历史" },
      -- 查找
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "缓冲区" },
      { "<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, desc = "缓冲区（全部）" },
      { "<leader>fc", LazyVim.pick.config_files(), desc = "查找配置文件" },
      { "<leader>ff", LazyVim.pick("files"), desc = "查找文件（根目录）" },
      { "<leader>fF", LazyVim.pick("files", { root = false }), desc = "查找文件（cwd）" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "查找文件（git-files）" },
      { "<leader>fr", LazyVim.pick("oldfiles"), desc = "最近" },
      { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "最近（cwd）" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "项目" },
      -- git
      { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git 差异（代码块）" },
      { "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, desc = "Git 差异（origin）" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git 状态" },
      { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git 储藏" },
      { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issue（未关闭）" },
      { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issue（全部）" },
      { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub PR（未关闭）" },
      { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub PR（全部）" },
      -- 搜索文本
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "缓冲区行" },
      { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "在已打开的缓冲区中搜索" },
      { "<leader>sg", LazyVim.pick("live_grep"), desc = "搜索文本（根目录）" },
      { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "搜索文本（cwd）" },
      { "<leader>sp", function() Snacks.picker.lazy() end, desc = "搜索插件配置" },
      { "<leader>sw", LazyVim.pick("grep_word"), desc = "可视区域或单词（根目录）", mode = { "n", "x" } },
      { "<leader>sW", LazyVim.pick("grep_word", { root = false }), desc = "可视区域或单词（cwd）", mode = { "n", "x" } },
      -- 搜索
      { '<leader>s"', function() Snacks.picker.registers() end, desc = "寄存器" },
      { '<leader>s/', function() Snacks.picker.search_history() end, desc = "搜索历史" },
      { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "自动命令" },
      { "<leader>sc", function() Snacks.picker.command_history() end, desc = "命令历史" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "命令" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "诊断" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "缓冲区诊断" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "帮助页面" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "高亮" },
      { "<leader>si", function() Snacks.picker.icons() end, desc = "图标" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "跳转" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "键位" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "位置列表" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Man 页面" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "标记" },
      { "<leader>sR", function() Snacks.picker.resume() end, desc = "继续上次选择" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "快速修复列表" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "撤销树" },
      -- 界面
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "配色方案" },
    },
  },
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      if LazyVim.has("trouble.nvim") then
        return vim.tbl_deep_extend("force", opts or {}, {
          picker = {
            actions = {
              trouble_open = function(...)
                return require("trouble.sources.snacks").actions.trouble_open.action(...)
              end,
            },
            win = {
              input = {
                keys = {
                  ["<a-t>"] = {
                    "trouble_open",
                    mode = { "n", "i" },
                  },
                },
              },
            },
          },
        })
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
            { "gd", function() Snacks.picker.lsp_definitions() end, desc = "转到定义", has = "definition" },
            { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "引用" },
            { "gI", function() Snacks.picker.lsp_implementations() end, desc = "转到实现" },
            { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "转到类[y]型定义" },
            { "<leader>ss", function() Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP 符号", has = "documentSymbol" },
            { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP 工作区符号", has = "workspace/symbols" },
            { "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "传入的调[a]用", has = "callHierarchy/incomingCalls" },
            { "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "发出的调[a]用", has = "callHierarchy/outgoingCalls" },
          },
        },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    optional = true,
    -- stylua: ignore
    keys = {
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "待办事项" },
      { "<leader>sT", function () Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "待办/修复/待修复" },
    },
  },
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      table.insert(opts.dashboard.preset.keys, 3, {
        icon = " ",
        key = "p",
        desc = "项目",
        action = ":lua Snacks.picker.projects()",
      })
    end,
  },
  {
    "goolord/alpha-nvim",
    optional = true,
    opts = function(_, dashboard)
      local button = dashboard.button("p", " " .. " Projects", [[<cmd> lua Snacks.picker.projects() <cr>]])
      button.opts.hl = "AlphaButtons"
      button.opts.hl_shortcut = "AlphaShortcut"
      table.insert(dashboard.section.buttons.val, 4, button)
    end,
  },
  {
    "nvim-mini/mini.starter",
    optional = true,
    opts = function(_, opts)
      local items = {
        {
          name = "Projects",
          action = [[lua Snacks.picker.projects()]],
          section = string.rep(" ", 22) .. "Telescope",
        },
      }
      vim.list_extend(opts.items, items)
    end,
  },
  {
    "nvimdev/dashboard-nvim",
    optional = true,
    opts = function(_, opts)
      if not vim.tbl_get(opts, "config", "center") then
        return
      end
      local projects = {
        action = "lua Snacks.picker.projects()",
        desc = " 项目",
        icon = " ",
        key = "p",
      }

      projects.desc = projects.desc .. string.rep(" ", 43 - vim.fn.strdisplaywidth(projects.desc))
      projects.key_format = "  %s"

      table.insert(opts.config.center, 3, projects)
    end,
  },
  {
    "folke/flash.nvim",
    optional = true,
    specs = {
      {
        "folke/snacks.nvim",
        opts = {
          picker = {
            win = {
              input = {
                keys = {
                  ["<a-s>"] = { "flash", mode = { "n", "i" } },
                  ["s"] = { "flash" },
                },
              },
            },
            actions = {
              flash = function(picker)
                require("flash").jump({
                  pattern = "^",
                  label = { after = { 0, 0 } },
                  search = {
                    mode = "search",
                    exclude = {
                      function(win)
                        return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                      end,
                    },
                  },
                  action = function(match)
                    local idx = picker.list:row2idx(match.pos[1])
                    picker.list:_move(idx, true, true)
                  end,
                })
              end,
            },
          },
        },
      },
    },
  },
}
