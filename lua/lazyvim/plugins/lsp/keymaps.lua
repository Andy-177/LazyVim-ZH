local M = {}

---@type LazyKeysLspSpec[]|nil
M._keys = {}

---@alias LazyKeysLspSpec LazyKeysSpec|{has?:string|string[], enabled?:(fun(buf:number):boolean)}
---@alias LazyKeysLsp LazyKeys|{has?:string|string[], enabled?:fun(buf:number):boolean}

---@deprecated
---@return LazyKeysLspSpec[]
function M.get()
  LazyVim.warn({
    '通过 `require("lazyvim.plugins.lsp.keymaps").get()` 添加 LSP 键位的方式已废弃。',
    "请改用 LSP 服务器配置中的 `keys` 字段来设置键位。",
    [[
```lua
{
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ['*'] = {
        keys = {
          { "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", has = "definition"},
        },
      },
    },
  },
}
```]],
  }, { stacktrace = true })
  vim.schedule(function()
    if #M._keys > 0 then
      M.set({}, M._keys)
      M._keys = {}
    end
  end)
  return M._keys
end

---@param filter vim.lsp.get_clients.Filter
---@param spec LazyKeysLspSpec[]
function M.set(filter, spec)
  local Keys = require("lazy.core.handler.keys")
  for _, keys in pairs(Keys.resolve(spec)) do
    ---@cast keys LazyKeysLsp
    local filters = {} ---@type vim.lsp.get_clients.Filter[]
    if keys.has then
      local methods = type(keys.has) == "string" and { keys.has } or keys.has --[[@as string[] ]]
      for _, method in ipairs(methods) do
        method = method:find("/") and method or ("textDocument/" .. method)
        filters[#filters + 1] = vim.tbl_extend("force", vim.deepcopy(filter), { method = method })
      end
    else
      filters[#filters + 1] = filter
    end

    for _, f in ipairs(filters) do
      local opts = Keys.opts(keys)
      ---@cast opts snacks.keymap.set.Opts
      opts.lsp = f
      opts.enabled = keys.enabled
      Snacks.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
    end
  end
end

return M
