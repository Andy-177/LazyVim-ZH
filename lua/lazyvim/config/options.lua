-- 此文件由 plugins.core 自动加载
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- LazyVim 自动格式化
vim.g.autoformat = true

-- Snacks 动画
-- 设为 `false` 可全局关闭所有 snacks 动画
vim.g.snacks_animate = true

-- 要使用的 LazyVim 选择器（picker）。
-- 可选值之一：telescope, fzf
-- 保持 "auto" 即可自动使用选择器
-- 通过 `:LazyExtras` 启用
vim.g.lazyvim_picker = "auto"

-- 要使用的 LazyVim 补全引擎。
-- 可选值之一：nvim-cmp, blink.cmp
-- 保持 "auto" 即可自动使用补全引擎
-- 通过 `:LazyExtras` 启用
vim.g.lazyvim_cmp = "auto"

-- 如果补全引擎支持 AI 数据源，
-- 则使用它代替内联建议
vim.g.ai_cmp = true

-- LazyVim 根目录检测
-- 每一项可以是：
-- * 形如 `lsp` 或 `cwd` 的检测器函数名
-- * 形如 `.git` 或 `lua` 的模式或模式数组
-- * 签名为 `function(buf) -> string|string[]` 的函数
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

-- 可选：设置要使用的终端
-- 这会设置 `vim.o.shell`，并为以下终端做一些额外配置：
-- * pwsh
-- * powershell
-- LazyVim.terminal.setup("pwsh")

-- 设置在配合 `util.root.detectors.lsp` 检测 LSP 根目录时
-- 需要忽略的 LSP 服务器
vim.g.root_lsp_ignore = { "copilot" }

-- 隐藏弃用警告
vim.g.deprecation_warnings = false

-- 在 lualine 中显示来自 Trouble 的当前文档符号位置
-- 你可以为某个缓冲区设置 `vim.b.trouble_lualine = false` 来禁用
vim.g.trouble_lualine = true

local opt = vim.opt

opt.autowrite = true -- 启用自动写入
-- 仅在非 ssh 环境下设置剪贴板，以确保 OSC 52
-- 集成能够自动工作。
opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus" -- 与系统剪贴板同步
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 2 -- 隐藏粗体和斜体使用的 * 标记，但不隐藏带替换的标记
opt.confirm = true -- 退出已修改的缓冲区前确认保存更改
opt.cursorline = true -- 高亮显示当前行
opt.expandtab = true -- 使用空格代替制表符
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.foldtext = ""
opt.formatexpr = "v:lua.LazyVim.format.formatexpr()"
opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true -- 忽略大小写
opt.inccommand = "nosplit" -- 预览式增量替换
opt.jumpoptions = "view"
opt.laststatus = 3 -- 全局状态栏
opt.linebreak = true -- 在合适的位置折行
opt.list = true -- 显示部分不可见字符（制表符……
opt.mouse = "a" -- 启用鼠标模式
opt.number = true -- 显示行号
opt.pumblend = 10 -- 弹出菜单背景色透明度
opt.pumheight = 10 -- 弹出菜单中的最大条目数
opt.relativenumber = true -- 相对行号
opt.ruler = false -- 禁用默认的标尺
opt.scrolloff = 4 -- 上下文行数
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shiftround = true -- 对齐缩进
opt.shiftwidth = 2 -- 缩进宽度
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false -- 已经有状态栏，所以不显示模式
opt.sidescrolloff = 8 -- 上下文列数
opt.signcolumn = "yes" -- 始终显示符号栏，否则每次都会让文本发生偏移
opt.smartcase = true -- 含大写字母时不忽略大小写
opt.smartindent = true -- 自动缩进
opt.smoothscroll = true
opt.spelllang = { "en" }
opt.splitbelow = true -- 新窗口置于当前窗口下方
opt.splitkeep = "screen"
opt.splitright = true -- 新窗口置于当前窗口右侧
opt.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
opt.tabstop = 2 -- 制表符宽度
opt.termguicolors = true -- 真彩色支持
opt.timeoutlen = vim.g.vscode and 1000 or 300 -- 低于默认值（1000）以更快触发 which-key
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200 -- 保存交换文件并触发 CursorHold
opt.virtualedit = "block" -- 允许光标在可视块模式的空白处移动
opt.wildmode = "longest:full,full" -- 命令行补全模式
opt.winminwidth = 5 -- 最小窗口宽度
opt.wrap = false -- 禁用自动换行

-- 修正 markdown 的缩进设置
vim.g.markdown_recommended_style = 0
