local LazyUtil = require("lazy.core.util")

---@class lazyvim.util: LazyUtilCore
---@field config LazyVimConfig
---@field treesitter lazyvim.util.treesitter
---@field lsp lazyvim.util.lsp
---@field root lazyvim.util.root
---@field terminal lazyvim.util.terminal
---@field format lazyvim.util.format
---@field plugin lazyvim.util.plugin
---@field extras lazyvim.util.extras
---@field inject lazyvim.util.inject
---@field news lazyvim.util.news
---@field json lazyvim.util.json
---@field lualine lazyvim.util.lualine
---@field mini lazyvim.util.mini
---@field pick lazyvim.util.pick
---@field cmp lazyvim.util.cmp
---@field deprecated lazyvim.util.deprecated
local M = {}
M.deprecated = require("lazyvim.util.deprecated")

setmetatable(M, {
  __index = function(t, k)
    if LazyUtil[k] then
      return LazyUtil[k]
    end
    if M.deprecated[k] then
      return M.deprecated[k]()
    end
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require("lazyvim.util." .. k)
    M.deprecated.decorate(k, t[k])
    return t[k]
  end,
})

function M.is_win()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---@param name string
function M.get_plugin(name)
  return require("lazy.core.config").spec.plugins[name]
end

---@param name string
---@param path string?
function M.get_plugin_path(name, path)
  local plugin = M.get_plugin(name)
  path = path and "/" .. path or ""
  return plugin and (plugin.dir .. path)
end

---@param plugin string
function M.has(plugin)
  return M.get_plugin(plugin) ~= nil
end

-- 检查某个扩展是否已启用：
-- * 该模块已被导入
-- * 该模块由 LazyExtras 添加
-- * 该模块出现在用户的 lazy 导入中
---@param extra string
function M.has_extra(extra)
  local Config = require("lazyvim.config")
  local modname = "lazyvim.plugins.extras." .. extra
  local LazyConfig = require("lazy.core.config")
  -- 检查是否已经被导入
  if vim.tbl_contains(LazyConfig.spec.modules, modname) then
    return true
  end
  -- 检查是否由 LazyExtras 添加
  if vim.tbl_contains(Config.json.data.extras, modname) then
    return true
  end
  -- 检查它是否在导入列表中
  local spec = LazyConfig.options.spec
  if type(spec) == "table" then
    for _, s in ipairs(spec) do
      if type(s) == "table" and s.import == modname then
        return true
      end
    end
  end
  return false
end

---@param fn fun()
function M.on_very_lazy(fn)
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      fn()
    end,
  })
end

--- 这会向表中的某个键（以点分隔的字符串表示）追加一个深层嵌套列表
-- 若该嵌套列表不存在则会被创建。

---@generic T
---@param t T[]
---@param key string
---@param values T[]
---@return T[]?
function M.extend(t, key, values)
  local keys = vim.split(key, ".", { plain = true })
  for i = 1, #keys do
    local k = keys[i]
    t[k] = t[k] or {}
    if type(t) ~= "table" then
      return
    end
    t = t[k]
  end
  return vim.list_extend(t, values)
end

---@param name string
function M.opts(name)
  local plugin = M.get_plugin(name)
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

---@param opts? LazyNotifyOpts
function M.deprecate(old, new, opts)
  M.warn(
    ("`%s` 已废弃，请改用 `%s`"):format(old, new),
    vim.tbl_extend("force", {
      title = "LazyVim",
      once = true,
      stacktrace = true,
      stacklevel = 6,
    }, opts or {})
  )
end

-- 延迟通知，直到 vim.notify 被替换或超过 500 毫秒
function M.lazy_notify()
  local notifs = {}
  local function temp(...)
    table.insert(notifs, vim.F.pack_len(...))
  end

  local orig = vim.notify
  vim.notify = temp

  local timer = vim.uv.new_timer()
  local check = assert(vim.uv.new_check())

  local replay = function()
    timer:stop()
    check:stop()
    if vim.notify == temp then
      -- 如有需要，恢复原有的 notify
    end
    vim.schedule(function()
      ---@diagnostic disable-next-line: no-unknown
      for _, notif in ipairs(notifs) do
        vim.notify(vim.F.unpack_len(notif))
      end
    end)
  end

  -- 等待 vim.notify 被替换
  check:start(function()
    if vim.notify ~= temp then
      replay()
    end
  end)
  -- 若超过 500 毫秒仍未替换，说明出了问题
  timer:start(500, 0, replay)
end

function M.is_loaded(name)
  local Config = require("lazy.core.config")
  return Config.plugins[name] and Config.plugins[name]._.loaded
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
  if M.is_loaded(name) then
    fn(name)
  else
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyLoad",
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

-- vim.keymap.set 的安全包装，
-- 当存在 lazy 键位处理器时不会创建键位。
-- 同时默认将 `silent` 设为 true。
function M.safe_keymap_set(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  local modes = type(mode) == "string" and { mode } or mode

  ---@param m string
  modes = vim.tbl_filter(function(m)
    return not (keys.have and keys:have(lhs, m))
  end, modes)

  -- 若存在 lazy 键位处理器，则不创建该键位
  if #modes > 0 then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    if opts.remap and not vim.g.vscode then
      ---@diagnostic disable-next-line: no-unknown
      opts.remap = nil
    end
    Snacks.keymap.set(modes, lhs, rhs, opts)
  end
end

---@generic T
---@param list T[]
---@return T[]
function M.dedup(list)
  local ret = {}
  local seen = {}
  for _, v in ipairs(list) do
    if not seen[v] then
      table.insert(ret, v)
      seen[v] = true
    end
  end
  return ret
end

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
  if vim.api.nvim_get_mode().mode == "i" then
    vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
  end
end

-- 获取 Mason 注册表中某个包的路径。
-- 优先使用它而不是 `get_package`，因为该包不一定总是
-- 可用，从而触发错误。
---@param pkg string
---@param path? string
---@param opts? { warn?: boolean }
function M.get_pkg_path(pkg, path, opts)
  -- pcall(require, "mason") -- 确保 Mason 已加载。生成文档时会失败
  local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
  opts = opts or {}
  opts.warn = opts.warn == nil and true or opts.warn
  path = path or ""
  local ret = vim.fs.normalize(root .. "/packages/" .. pkg .. "/" .. path)
  if opts.warn then
    vim.schedule(function()
      if not require("lazy.core.config").headless() and not vim.loop.fs_stat(ret) then
        M.warn(
          ("未找到 **%s** 的 Mason 包路径：\n- `%s`\n你可能需要强制更新该包。"):format(
            pkg,
            path
          )
        )
      end
    end)
  end
  return ret
end

-- 覆盖通知的默认标题。
for _, level in ipairs({ "info", "warn", "error" }) do
  M[level] = function(msg, opts)
    opts = opts or {}
    opts.title = opts.title or "LazyVim"
    return LazyUtil[level](msg, opts)
  end
end

local cache = {} ---@type table<(fun()), table<string, any>>
---@generic T: fun()
---@param fn T
---@return T
function M.memoize(fn)
  return function(...)
    local key = vim.inspect({ ... })
    cache[fn] = cache[fn] or {}
    if cache[fn][key] == nil then
      cache[fn][key] = fn(...)
    end
    return cache[fn][key]
  end
end

-- snacks 的安全包装，避免 LazyVim 仍在安装时出错
function M.statuscolumn()
  return package.loaded.snacks and require("snacks.statuscolumn").get() or ""
end

local _defaults = {} ---@type table<string, boolean>

-- 判断将某个选项设为默认值是否安全。
--
-- 只有在满足以下条件时才会设置该选项：
-- * 它与全局值相同
-- * 它的当前值是默认值
-- * 它最后是由 $VIMRUNTIME 中的脚本设置的
---@param option string
---@param value string|number|boolean
---@return boolean was_set
function M.set_default(option, value)
  local l = vim.api.nvim_get_option_value(option, { scope = "local" })
  local g = LazyVim.config._options[option] or vim.api.nvim_get_option_value(option, { scope = "global" })

  _defaults[("%s=%s"):format(option, value)] = true
  local key = ("%s=%s"):format(option, l)

  local source = ""
  if l ~= g and not _defaults[key] then
    -- 该选项与全局值不同，且不是默认值
    -- 检查它是否由 $VIMRUNTIME 中的脚本设置
    local info = vim.api.nvim_get_option_info2(option, { scope = "local" })
    ---@param e vim.fn.getscriptinfo.ret
    local scriptinfo = vim.tbl_filter(function(e)
      return e.sid == info.last_set_sid
    end, vim.fn.getscriptinfo())
    source = scriptinfo[1] and scriptinfo[1].name or ""
    local by_rtp = #scriptinfo == 1 and vim.startswith(scriptinfo[1].name, vim.fn.expand("$VIMRUNTIME"))
    if not by_rtp then
      if vim.g.lazyvim_debug_set_default then
        LazyVim.warn(
          ("未将选项 `%s` 设为 `%q`，因为它已被某个插件修改。"):format(option, value),
          { title = "LazyVim", once = true }
        )
      end
      return false
    end
  end

  if vim.g.lazyvim_debug_set_default then
    LazyVim.info({
      ("将选项 `%s` 设为 `%q`"):format(option, value),
      ("原值：%q"):format(l),
      ("全局值：%q"):format(g),
      source ~= "" and ("最后设置者：%s"):format(source) or "",
      "buf: " .. vim.api.nvim_buf_get_name(0),
    }, { title = "LazyVim", once = true })
  end

  vim.api.nvim_set_option_value(option, value, { scope = "local" })
  return true
end

return M
