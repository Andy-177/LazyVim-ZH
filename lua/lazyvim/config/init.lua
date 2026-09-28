_G.LazyVim = require("lazyvim.util")

---@class LazyVimConfig: LazyVimOptions
local M = {}

M.version = "16.0.1" -- x-release-please-version
LazyVim.config = M

---@class LazyVimOptions
local defaults = {
  -- colorscheme 可以是形如 `catppuccin` 的字符串，也可以是一个负责加载配色方案的函数
  ---@type string|fun()
  colorscheme = function()
    require("tokyonight").load()
  end,
  -- 加载默认配置
  defaults = {
    autocmds = true, -- lazyvim.config.autocmds
    keymaps = true, -- lazyvim.config.keymaps
    -- lazyvim.config.options 不能在这里配置，因为它在 lazyvim setup 之前就已加载
    -- 如果你想禁用 options 的加载，请在 init.lua 顶部添加 `package.loaded["lazyvim.config.options"] = true`
  },
  news = {
    -- 启用后，NEWS.md 发生变化时会显示。
    -- 这里只包含重要的新功能和不兼容变更。
    lazyvim = true,
    -- 同上，但用于 Neovim 的 news.txt
    neovim = false,
  },
  -- 供其它插件使用的图标
  -- stylua: ignore
  icons = {
    misc = {
      dots = "󰇘",
    },
    ft = {
      octo = " ",
      gh = " ",
      ["markdown.gh"] = " ",
    },
    dap = {
      Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
      Breakpoint          = " ",
      BreakpointCondition = " ",
      BreakpointRejected  = { " ", "DiagnosticError" },
      LogPoint            = ".>",
    },
    diagnostics = {
      Error = " ",
      Warn  = " ",
      Hint  = " ",
      Info  = " ",
    },
    git = {
      added    = " ",
      modified = " ",
      removed  = " ",
    },
    kinds = {
      Array         = " ",
      Boolean       = "󰨙 ",
      Class         = " ",
      Codeium       = "󰘦 ",
      Color         = " ",
      Control       = " ",
      Collapsed     = " ",
      Constant      = "󰏿 ",
      Constructor   = " ",
      Copilot       = " ",
      Enum          = " ",
      EnumMember    = " ",
      Event         = " ",
      Field         = " ",
      File          = " ",
      Folder        = " ",
      Function      = "󰊕 ",
      Interface     = " ",
      Key           = " ",
      Keyword       = " ",
      Method        = "󰊕 ",
      Module        = " ",
      Namespace     = "󰦮 ",
      Null          = " ",
      Number        = "󰎠 ",
      Object        = " ",
      Operator      = " ",
      Package       = " ",
      Property      = " ",
      Reference     = " ",
      Snippet       = "󱄽 ",
      String        = " ",
      Struct        = "󰆼 ",
      Supermaven    = " ",
      TabNine       = "󰏚 ",
      Text          = " ",
      TypeParameter = " ",
      Unit          = " ",
      Value         = " ",
      Variable      = "󰀫 ",
    },
  },
  ---@type table<string, string[]|boolean>?
  kind_filter = {
    default = {
      "Class",
      "Constructor",
      "Enum",
      "Field",
      "Function",
      "Interface",
      "Method",
      "Module",
      "Namespace",
      "Package",
      "Property",
      "Struct",
      "Trait",
    },
    markdown = false,
    help = false,
    -- 你可以为每种文件类型指定不同的过滤列表
    lua = {
      "Class",
      "Constructor",
      "Enum",
      "Field",
      "Function",
      "Interface",
      "Method",
      "Module",
      "Namespace",
      -- "Package", -- 移除 package，因为 luals 将其用于控制流结构
      "Property",
      "Struct",
      "Trait",
    },
  },
}

M.json = {
  version = 8,
  loaded = false,
  path = vim.g.lazyvim_json or vim.fn.stdpath("config") .. "/lazyvim.json",
  data = {
    version = nil, ---@type number?
    install_version = nil, ---@type number?
    news = {}, ---@type table<string, string>
    extras = {}, ---@type string[]
  },
}

function M.json.load()
  M.json.loaded = true
  local f = io.open(M.json.path, "r")
  if f then
    local data = f:read("*a")
    f:close()
    local ok, json = pcall(vim.json.decode, data, { luanil = { object = true, array = true } })
    if ok then
      M.json.data = vim.tbl_deep_extend("force", M.json.data, json or {})
      if M.json.data.version ~= M.json.version then
        LazyVim.json.migrate()
      end
    end
  else
    M.json.data.install_version = M.json.version
  end
end

---@type LazyVimOptions
local options
local lazy_clipboard

---@param opts? LazyVimOptions
function M.setup(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {}) or {}

  -- 未打开文件时，autocmds 可以延迟加载
  local lazy_autocmds = vim.fn.argc(-1) == 0
  if not lazy_autocmds then
    M.load("autocmds")
  end

  local group = vim.api.nvim_create_augroup("LazyVim", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    callback = function()
      if lazy_autocmds then
        M.load("autocmds")
      end
      M.load("keymaps")
      if lazy_clipboard ~= nil then
        vim.opt.clipboard = lazy_clipboard
      end

      LazyVim.format.setup()
      LazyVim.news.setup()
      LazyVim.root.setup()

      vim.api.nvim_create_user_command("LazyExtras", function()
        LazyVim.extras.show()
      end, { desc = "管理 LazyVim 扩展" })

      vim.api.nvim_create_user_command("LazyHealth", function()
        vim.cmd([[Lazy! load all]])
        vim.cmd([[checkhealth]])
      end, { desc = "加载所有插件并运行 :checkhealth" })

      local health = require("lazy.health")
      vim.list_extend(health.valid, {
        "recommended",
        "desc",
        "vscode",
      })

      if vim.g.lazyvim_check_order == false then
        return
      end

      -- 检查 lazy.nvim 的导入顺序
      local imports = require("lazy.core.config").spec.modules
      local function find(pat, last)
        for i = last and #imports or 1, last and 1 or #imports, last and -1 or 1 do
          if imports[i]:find(pat) then
            return i
          end
        end
      end
      local lazyvim_plugins = find("^lazyvim%.plugins$")
      local extras = find("^lazyvim%.plugins%.extras%.", true) or lazyvim_plugins
      local plugins = find("^plugins$") or math.huge
      if lazyvim_plugins ~= 1 or extras > plugins then
        local msg = {
          "你的 `lazy.nvim` 导入顺序不正确：",
          "- `lazyvim.plugins` 应当排在最前",
          "- 其次是任意 `lazyvim.plugins.extras`",
          "- 最后是你自己的 `plugins`",
          "",
          "如果你清楚自己在做什么，可以用下面的方式关闭该检查：",
          "```lua",
          "vim.g.lazyvim_check_order = false",
          "```",
        }
        vim.notify(table.concat(msg, "\n"), "warn", { title = "LazyVim" })
      end
    end,
  })

  LazyVim.track("colorscheme")
  LazyVim.try(function()
    if type(M.colorscheme) == "function" then
      M.colorscheme()
    else
      vim.cmd.colorscheme(M.colorscheme)
    end
  end, {
    msg = "无法加载你的配色方案",
    on_error = function(msg)
      LazyVim.error(msg)
      vim.cmd.colorscheme("habamax")
    end,
  })
  LazyVim.track()
end

---@param buf? number
---@return string[]?
function M.get_kind_filter(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local ft = vim.bo[buf].filetype
  if M.kind_filter == false then
    return
  end
  if M.kind_filter[ft] == false then
    return
  end
  if type(M.kind_filter[ft]) == "table" then
    return M.kind_filter[ft]
  end
  ---@diagnostic disable-next-line: return-type-mismatch
  return type(M.kind_filter) == "table" and type(M.kind_filter.default) == "table" and M.kind_filter.default or nil
end

---@param name "autocmds" | "options" | "keymaps"
function M.load(name)
  local function _load(mod)
    if require("lazy.core.cache").find(mod)[1] then
      LazyVim.try(function()
        require(mod)
      end, { msg = "加载失败 " .. mod })
    end
  end
  local pattern = "LazyVim" .. name:sub(1, 1):upper() .. name:sub(2)
  -- 总是先加载 lazyvim，再加载用户文件
  if M.defaults[name] or name == "options" then
    _load("lazyvim.config." .. name)
    vim.api.nvim_exec_autocmds("User", { pattern = pattern .. "Defaults", modeline = false })
  end
  _load("config." .. name)
  if vim.bo.filetype == "lazy" then
    -- 变通方案：LazyVim 可能覆盖了 Lazy 界面的选项，所以在这里重置
    vim.cmd([[do VimResized]])
  end
  vim.api.nvim_exec_autocmds("User", { pattern = pattern, modeline = false })
end

M.did_init = false
M._options = {} ---@type vim.wo|vim.bo

function M.init()
  if M.did_init then
    return
  end
  M.did_init = true
  local plugin = require("lazy.core.config").spec.plugins.LazyVim
  if plugin then
    vim.opt.rtp:append(plugin.dir)
  end

  package.preload["lazyvim.plugins.lsp.format"] = function()
    LazyVim.deprecate([[require("lazyvim.plugins.lsp.format")]], [[LazyVim.format]])
    return LazyVim.format
  end

  -- 延迟通知，直到 vim.notify 被替换或超过 500 毫秒
  LazyVim.lazy_notify()

  -- 在这里加载 options，即在 lazy 初始化、加载插件模块之前
  -- 这样可以确保在安装缺失的插件之后
  -- options 能够被正确应用
  M.load("options")

  -- 保存部分选项以跟踪默认值
  M._options.indentexpr = vim.o.indentexpr
  M._options.foldmethod = vim.o.foldmethod
  M._options.foldexpr = vim.o.foldexpr

  -- 延迟处理内置剪贴板："xsel" 和 "pbcopy" 可能较慢
  lazy_clipboard = vim.opt.clipboard:get()
  vim.opt.clipboard = ""

  if vim.g.deprecation_warnings == false then
    vim.deprecate = function() end
  end

  LazyVim.plugin.setup()
  M.json.load()
end

---@alias LazyVimDefault {name: string, group: string, extra: string, import: string, enabled?: boolean, origin?: "global" | "default" | "extra" }
---
local default_extras ---@type table<string, LazyVimDefault>

---@param name string
---@param extras LazyVimDefault[]
function M.register_defaults(name, extras)
  assert(default_extras, "默认值此时应该已经加载，这不应发生")
  local valid = vim.tbl_map(function(extra)
    return extra.name
  end, extras) --[[@as string[] ]]

  local origin = "default"
  local ret ---@type LazyVimDefault?
  local use ---@type string?

  local global = vim.g["lazyvim_" .. name]
  if vim.tbl_contains(valid, global) then
    origin = "global" -- 由用户在配置中设置
    use = global
  else
    if global and global ~= "auto" then
      vim.notify(
        ("`vim.g.lazyvim_%s` 的值无效：`%s`\n可选值为：%s"):format(
          name,
          global,
          table.concat(valid, ", ")
        ),
        vim.log.levels.ERROR,
        { title = "LazyVim" }
      )
    end
    for _, extra in ipairs(extras) do
      if LazyVim.has_extra(extra.extra) then
        use = extra.name -- 由用户在 lazy 配置中导入，或通过 LazyExtras 添加
        origin = "extra"
        break
      end
    end
  end

  use = use or valid[1] -- 若未设置任何值，则回退到第一个

  for _, extra in ipairs(extras) do
    local import = "lazyvim.plugins.extras." .. extra.extra
    extra = vim.deepcopy(extra)
    extra.enabled = extra.name == use
    extra.import = import
    extra.group = name
    if extra.enabled then
      extra.origin = origin
      ret = extra
    end
    default_extras[import] = extra
  end

  return assert(ret, "应该至少有一个扩展被启用，这不应发生")
end

---@param group string
---@return LazyVimDefault?
function M.get_default(group)
  for _, extra in pairs(M.get_defaults()) do
    if extra.group == group and extra.enabled then
      return extra
    end
  end
end

function M.get_defaults()
  if default_extras then
    return default_extras
  end
  default_extras = {}

  ---@type table<string, LazyVimDefault[]>
  local checks = {
    picker = {
      { name = "snacks", extra = "editor.snacks_picker" },
      { name = "fzf", extra = "editor.fzf" },
      { name = "telescope", extra = "editor.telescope" },
    },
    cmp = {
      { name = "blink.cmp", extra = "coding.blink" },
      { name = "nvim-cmp", extra = "coding.nvim-cmp" },
    },
    explorer = {
      { name = "snacks", extra = "editor.snacks_explorer" },
      { name = "neo-tree", extra = "editor.neo-tree" },
    },
  }

  -- 已有的安装保留其默认值
  if (LazyVim.config.json.data.install_version or 7) < 8 then
    table.insert(checks.picker, 1, table.remove(checks.picker, 2))
    table.insert(checks.explorer, 1, table.remove(checks.explorer, 2))
  end

  for name, extras in pairs(checks) do
    M.register_defaults(name, extras)
  end

  return default_extras
end

setmetatable(M, {
  __index = function(_, key)
    if options == nil then
      return vim.deepcopy(defaults)[key]
    end
    ---@cast options LazyVimConfig
    return options[key]
  end,
})

return M
