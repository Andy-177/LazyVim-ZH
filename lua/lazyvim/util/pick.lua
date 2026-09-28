---@class lazyvim.util.pick
---@overload fun(command:string, opts?:lazyvim.util.pick.Opts): fun()
local M = setmetatable({}, {
  __call = function(m, ...)
    return m.wrap(...)
  end,
})

---@class lazyvim.util.pick.Opts: table<string, any>
---@field root? boolean
---@field cwd? string
---@field buf? number
---@field show_untracked? boolean

---@class LazyPicker
---@field name string
---@field open fun(command:string, opts?:lazyvim.util.pick.Opts)
---@field commands table<string, string>

---@type LazyPicker?
M.picker = nil

---@param picker LazyPicker
function M.register(picker)
  -- 这只会在使用 :LazyExtras 时发生
  -- 因此允许获取完整的 spec
  if vim.v.vim_did_enter == 1 then
    return true
  end

  if M.picker and M.picker.name ~= picker.name then
    LazyVim.warn(
      "`LazyVim.pick`：选择器已设置为 `" .. M.picker.name .. "`，\n忽略新的选择器 `" .. picker.name .. "`"
    )
    return false
  end
  M.picker = picker
  return true
end

---@param command? string
---@param opts? lazyvim.util.pick.Opts
function M.open(command, opts)
  if not M.picker then
    return LazyVim.error("LazyVim.pick：未设置选择器")
  end

  command = command ~= "auto" and command or "files"
  opts = opts or {}

  opts = vim.deepcopy(opts)

  if type(opts.cwd) == "boolean" then
    LazyVim.warn("LazyVim.pick：opts.cwd 应为字符串或 nil")
    opts.cwd = nil
  end

  if not opts.cwd and opts.root ~= false then
    opts.cwd = LazyVim.root({ buf = opts.buf })
  end

  command = M.picker.commands[command] or command
  M.picker.open(command, opts)
end

---@param command? string
---@param opts? lazyvim.util.pick.Opts
function M.wrap(command, opts)
  opts = opts or {}
  return function()
    LazyVim.pick.open(command, vim.deepcopy(opts))
  end
end

function M.config_files()
  return M.wrap("files", { cwd = vim.fn.stdpath("config") })
end

return M
