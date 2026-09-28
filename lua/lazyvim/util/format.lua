---@class lazyvim.util.format
---@overload fun(opts?: {force?:boolean})
local M = setmetatable({}, {
  __call = function(m, ...)
    return m.format(...)
  end,
})

---@class LazyFormatter
---@field name string
---@field primary? boolean
---@field format fun(bufnr:number)
---@field sources fun(bufnr:number):string[]
---@field priority number

M.formatters = {} ---@type LazyFormatter[]

---@param formatter LazyFormatter
function M.register(formatter)
  M.formatters[#M.formatters + 1] = formatter
  table.sort(M.formatters, function(a, b)
    return a.priority > b.priority
  end)
end

function M.formatexpr()
  if LazyVim.has("conform.nvim") then
    return require("conform").formatexpr()
  end
  return vim.lsp.formatexpr({ timeout_ms = 3000 })
end

---@param buf? number
---@return (LazyFormatter|{active:boolean,resolved:string[]})[]
function M.resolve(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local have_primary = false
  ---@param formatter LazyFormatter
  return vim.tbl_map(function(formatter)
    local sources = formatter.sources(buf)
    local active = #sources > 0 and (not formatter.primary or not have_primary)
    have_primary = have_primary or (active and formatter.primary) or false
    return setmetatable({
      active = active,
      resolved = sources,
    }, { __index = formatter })
  end, M.formatters)
end

---@param buf? number
function M.info(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local gaf = vim.g.autoformat == nil or vim.g.autoformat
  local baf = vim.b[buf].autoformat
  local enabled = M.enabled(buf)
  local lines = {
    "# 状态",
    ("- [%s] global **%s**"):format(gaf and "x" or " ", gaf and "已启用" or "已禁用"),
    ("- [%s] buffer **%s**"):format(
      enabled and "x" or " ",
      baf == nil and "继承" or baf and "已启用" or "已禁用"
    ),
  }
  local have = false
  for _, formatter in ipairs(M.resolve(buf)) do
    if #formatter.resolved > 0 then
      have = true
      lines[#lines + 1] = "\n# " .. formatter.name .. (formatter.active and " ***（使用中）***" or "")
      for _, line in ipairs(formatter.resolved) do
        lines[#lines + 1] = ("- [%s] **%s**"):format(formatter.active and "x" or " ", line)
      end
    end
  end
  if not have then
    lines[#lines + 1] = "\n***当前缓冲区没有可用的格式化程序。***"
  end
  LazyVim[enabled and "info" or "warn"](
    table.concat(lines, "\n"),
    { title = "LazyFormat（" .. (enabled and "已启用" or "已禁用") .. "）" }
  )
end

---@param buf? number
function M.enabled(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local gaf = vim.g.autoformat
  local baf = vim.b[buf].autoformat

  -- 如果该缓冲区有局部值，则使用它
  if baf ~= nil then
    return baf
  end

  -- 否则使用已设置的全局值，若未设置则默认为 true
  return gaf == nil or gaf
end

---@param buf? boolean
function M.toggle(buf)
  M.enable(not M.enabled(), buf)
end

---@param enable? boolean
---@param buf? boolean
function M.enable(enable, buf)
  if enable == nil then
    enable = true
  end
  if buf then
    vim.b.autoformat = enable
  else
    vim.g.autoformat = enable
    vim.b.autoformat = nil
  end
  M.info()
end

---@param opts? {force?:boolean, buf?:number}
function M.format(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  if not ((opts and opts.force) or M.enabled(buf)) then
    return
  end

  local done = false
  for _, formatter in ipairs(M.resolve(buf)) do
    if formatter.active then
      done = true
      LazyVim.try(function()
        return formatter.format(buf)
      end, { msg = "格式化程序 `" .. formatter.name .. "` 执行失败" })
    end
  end

  if not done and opts and opts.force then
    LazyVim.warn("没有可用的格式化程序", { title = "LazyVim" })
  end
end

function M.health()
  local Config = require("lazy.core.config")
  local has_plugin = Config.spec.plugins["none-ls.nvim"]
  local has_extra = vim.tbl_contains(Config.spec.modules, "lazyvim.plugins.extras.lsp.none-ls")
  if has_plugin and not has_extra then
    LazyVim.warn({
      "`conform.nvim` and `nvim-lint` are now the default formatters and linters in LazyVim.",
      "",
      "You can use those plugins together with `none-ls.nvim`,",
      "but you need to enable the `lazyvim.plugins.extras.lsp.none-ls` extra,",
      "for formatting to work correctly.",
      "",
      "In case you no longer want to use `none-ls.nvim`, just remove the spec from your config.",
    })
  end
end

function M.setup()
  M.health()

  -- 自动格式化自动命令
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("LazyFormat", {}),
    callback = function(event)
      M.format({ buf = event.buf })
    end,
  })

  -- 手动格式化
  vim.api.nvim_create_user_command("LazyFormat", function()
    M.format({ force = true })
  end, { desc = "格式化选中内容或当前缓冲区" })

  -- 格式化信息
  vim.api.nvim_create_user_command("LazyFormatInfo", function()
    M.info()
  end, { desc = "显示当前缓冲区所使用格式化程序的信息" })
end

---@param buf? boolean
function M.snacks_toggle(buf)
  return Snacks.toggle({
    name = "自动格式化（" .. (buf and "缓冲区" or "全局") .. "）",
    get = function()
      if not buf then
        return vim.g.autoformat == nil or vim.g.autoformat
      end
      return LazyVim.format.enabled()
    end,
    set = function(state)
      LazyVim.format.enable(state, buf)
    end,
  })
end

return M
