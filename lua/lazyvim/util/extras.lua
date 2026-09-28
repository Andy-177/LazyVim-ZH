local Float = require("lazy.view.float")
local LazyConfig = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Text = require("lazy.view.text")

---@class LazyExtraSource
---@field name string
---@field desc? string
---@field module string

---@class LazyExtra
---@field name string
---@field source LazyExtraSource
---@field module string
---@field desc? string
---@field enabled boolean
---@field managed boolean
---@field recommended? boolean
---@field imports string[]
---@field row? number
---@field section? string
---@field plugins string[]
---@field optional string[]

---@class lazyvim.util.extras
local M = {}
M.buf = 0

---@type LazyExtraSource[]
M.sources = {
  { name = "LazyVim", desc = "LazyVim 扩展", module = "lazyvim.plugins.extras" },
  { name = "用户", desc = "用户扩展", module = "plugins.extras" },
}

M.ns = vim.api.nvim_create_namespace("lazyvim.extras")
---@type string[]
M.state = nil

---@alias WantsOpts {ft?: string|string[], root?: string|string[]}

---@param opts WantsOpts
---@return boolean
function M.wants(opts)
  if opts.ft then
    opts.ft = type(opts.ft) == "string" and { opts.ft } or opts.ft
    for _, f in ipairs(opts.ft) do
      if vim.bo[M.buf].filetype == f then
        return true
      end
    end
  end
  if opts.root then
    opts.root = type(opts.root) == "string" and { opts.root } or opts.root
    return #LazyVim.root.detectors.pattern(M.buf, opts.root) > 0
  end
  return false
end

---@return LazyExtra[]
function M.get()
  M.state = M.state or LazyConfig.spec.modules
  local extras = {} ---@type LazyExtra[]
  for _, source in ipairs(M.sources) do
    local root = LazyVim.find_root(source.module)
    if root then
      LazyVim.walk(root, function(path, name, type)
        if (type == "file" or type == "link") and name:match("%.lua$") then
          name = path:sub(#root + 2, -5):gsub("/", "."):gsub("%.init$", "")
          local ok, extra = pcall(M.get_extra, source, source.module .. "." .. name)
          if ok then
            extras[#extras + 1] = extra
          end
        end
      end)
    end
  end
  table.sort(extras, function(a, b)
    return a.name < b.name
  end)
  return extras
end

---@param modname string
---@param source LazyExtraSource
function M.get_extra(source, modname)
  LazyVim.plugin.handle_defaults = false
  local enabled = vim.tbl_contains(M.state, modname)
  local spec = Plugin.Spec.new(nil, { optional = true, pkg = false })
  spec:parse({ import = modname })
  local imports = vim.tbl_filter(function(x)
    return x ~= modname
  end, spec.modules)
  if #imports > 0 then
    spec = Plugin.Spec.new(nil, { optional = true, pkg = false })
    spec.modules = vim.deepcopy(imports)
    spec:parse({ import = modname })
  end
  local plugins = {} ---@type string[]
  local optional = {} ---@type string[]
  for _, p in pairs(spec.plugins) do
    if p.optional then
      optional[#optional + 1] = p.name
    else
      plugins[#plugins + 1] = p.name
    end
  end
  table.sort(plugins)
  table.sort(optional)

  ---@type boolean|(fun():boolean?)|nil|WantsOpts
  local recommended = require(modname).recommended or false
  if type(recommended) == "function" then
    recommended = recommended() or false
  elseif type(recommended) == "table" then
    recommended = M.wants(recommended)
  end

  -- 因与其它已启用扩展冲突而被禁用的语言扩展不会标记为推荐
  local defaults = LazyVim.config.get_defaults()
  local def = defaults[modname]
  if def and def.enabled == false and vim.startswith(modname, "lazyvim.plugins.extras.lang.") then
    recommended = false
  end

  ---@type LazyExtra
  return {
    source = source,
    name = modname:sub(#source.module + 2),
    module = modname,
    enabled = enabled,
    imports = imports,
    desc = require(modname).desc,
    recommended = recommended,
    managed = vim.tbl_contains(LazyVim.config.json.data.extras, modname) or not enabled,
    plugins = plugins,
    optional = optional,
  }
end

---@class LazyExtraView
---@field float LazyFloat
---@field text Text
---@field extras LazyExtra[]
---@field diag LazyDiagnostic[]
local X = {}

---@return LazyExtraView
function X.new()
  local self = setmetatable({}, { __index = X })
  M.buf = vim.api.nvim_get_current_buf()
  self.float = Float.new({ title = "LazyVim 扩展" })
  self.float:on_key("x", function()
    self:toggle()
  end, "切换扩展")
  self.diag = {}
  self:update()
  return self
end

---@param diag LazyDiagnostic
function X:diagnostic(diag)
  diag.row = diag.row or self.text:row()
  diag.severity = diag.severity or vim.diagnostic.severity.INFO
  table.insert(self.diag, diag)
end

function X:toggle()
  local pos = vim.api.nvim_win_get_cursor(self.float.win)
  for _, extra in ipairs(self.extras) do
    if extra.row == pos[1] then
      if not extra.managed then
        LazyVim.error(
          "不受 LazyExtras 管理。请从你的配置中移除后再在此启用/禁用。",
          { title = "LazyExtras" }
        )
        return
      end
      extra.enabled = not extra.enabled
      LazyVim.config.json.data.extras = vim.tbl_filter(function(name)
        return name ~= extra.module
      end, LazyVim.config.json.data.extras)
      M.state = vim.tbl_filter(function(name)
        return name ~= extra.module
      end, M.state)
      if extra.enabled then
        table.insert(LazyVim.config.json.data.extras, extra.module)
        M.state[#M.state + 1] = extra.module
      end
      table.sort(LazyVim.config.json.data.extras)
      LazyVim.json.save()
      LazyVim.info(
        "`"
          .. extra.name
          .. "`"
          .. " "
          .. (extra.enabled and "**已启用**" or "**已禁用**")
          .. "\n请重启 LazyVim 以应用这些更改。",
        { title = "LazyExtras" }
      )
      self:update()
      return
    end
  end
end

function X:update()
  self.diag = {}
  self.extras = M.get()
  self.text = Text.new()
  self.text.padding = 2
  self:render()
  self.text:trim()
  vim.bo[self.float.buf].modifiable = true
  self.text:render(self.float.buf)
  vim.bo[self.float.buf].modifiable = false
  vim.diagnostic.set(
    M.ns,
    self.float.buf,
    ---@param diag LazyDiagnostic
    vim.tbl_map(function(diag)
      diag.col = 0
      diag.lnum = diag.row - 1
      return diag
    end, self.diag),
    { signs = false, virtual_text = true, underline = false }
  )
end

function X:render()
  self.text:nl():nl():append("LazyVim 扩展", "LazyH1"):nl():nl()
  self.text
    :append("这是所有已启用/已禁用的 LazyVim 扩展列表。", "LazyComment")
    :nl()
    :append("每个扩展都会显示它可能安装的必需插件和可选插件。", "LazyComment")
    :nl()
    :append("使用 ", "LazyComment")
    :append("<x>", "LazySpecial")
    :append(" 键启用/禁用扩展", "LazyComment")
    :nl()
  for _, extra in ipairs(self.extras) do
    extra.section = nil
  end
  self:section({
    recommended = true,
    enabled = false,
    include = "^lang%.",
    title = "推荐的语言",
    empty = false,
  })
  self:section({ enabled = true, exclude = "^lang%.", title = "已启用的插件" })
  self:section({ enabled = true, title = "已启用的语言" })
  self:section({ recommended = true, title = "推荐的插件", empty = false })
  self:section({ title = "插件", exclude = "^lang%." })
  self:section({ title = "语言" })
end

---@param extra LazyExtra
function X:extra(extra)
  local defaults = LazyVim.config.get_defaults()
  local def = defaults[extra.module]
  local origin = def and (def.origin or "user") or nil
  if not extra.managed then
    ---@type LazyExtra[]
    local parents = {}
    for _, x in ipairs(self.extras) do
      if x.enabled and vim.tbl_contains(x.imports, extra.module) then
        parents[#parents + 1] = x
      end
    end
    if #parents > 0 then
      local pp = vim.tbl_map(function(x)
        return x.name
      end, parents)
      self:diagnostic({
        message = "被以下扩展依赖：" .. table.concat(pp, "、"),
      })
    elseif vim.tbl_contains(LazyVim.plugin.core_imports, extra.module) or origin == "default" then
      self:diagnostic({
        message = "该扩展默认已包含",
      })
    else
      self:diagnostic({
        message = "不受 LazyExtras 管理（配置中）",
        severity = vim.diagnostic.severity.WARN,
      })
    end
  end
  extra.row = self.text:row()
  local hl = extra.managed and "LazySpecial" or "LazyLocal"
  if extra.enabled then
    self.text:append("  " .. LazyConfig.options.ui.icons.loaded .. " ", hl)
  else
    self.text:append("  " .. LazyConfig.options.ui.icons.not_loaded .. " ", hl)
  end
  self.text:append(extra.name)
  if extra.recommended then
    self.text:append(" "):append(LazyConfig.options.ui.icons.favorite or " ", "LazyCommit")
  end
  if extra.source.name ~= "LazyVim" then
    self.text:append(" "):append(LazyConfig.options.ui.icons.event .. extra.source.name, "LazyReasonEvent")
  end
  for _, import in ipairs(extra.imports) do
    import = import:gsub("^lazyvim.plugins.extras.", "")
    self.text:append(" "):append(LazyConfig.options.ui.icons.plugin .. import, "LazyReasonStart")
  end
  for _, plugin in ipairs(extra.plugins) do
    self.text:append(" "):append(LazyConfig.options.ui.icons.plugin .. plugin, "LazyReasonPlugin")
  end
  for _, plugin in ipairs(extra.optional) do
    self.text:append(" "):append(LazyConfig.options.ui.icons.plugin .. plugin, "LazyReasonRequire")
  end
  if extra.desc then
    self.text:nl():append("    " .. extra.desc, "LazyComment")
  end
  self.text:nl()
end

---@param opts {enabled?:boolean, title:string, recommended?:boolean, include?:string, exclude?:string, empty?:boolean}
function X:section(opts)
  opts = opts or {}
  ---@type LazyExtra[]
  local extras = vim.tbl_filter(function(extra)
    return extra.section == nil
      and (opts.enabled == nil or extra.enabled == opts.enabled)
      and (opts.recommended == nil or extra.recommended == opts.recommended)
      and (opts.include == nil or extra.name:find(opts.include))
      and (opts.exclude == nil or not extra.name:find(opts.exclude))
  end, self.extras)

  if opts.empty == false and #extras == 0 then
    return
  end

  self.text:nl():append(opts.title .. ":", "LazyH2"):append(" (" .. #extras .. ")", "LazyComment"):nl()
  for _, extra in ipairs(extras) do
    extra.section = opts.title
    self:extra(extra)
  end
end

function M.show()
  return X.new()
end

return M
