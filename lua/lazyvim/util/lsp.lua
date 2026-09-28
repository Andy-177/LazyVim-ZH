---@class lazyvim.util.lsp
local M = {}

---@param opts? LazyFormatter| {filter?: (string|vim.lsp.get_clients.Filter)}
function M.formatter(opts)
  opts = opts or {}
  local filter = opts.filter or {}
  filter = type(filter) == "string" and { name = filter } or filter
  ---@cast filter vim.lsp.get_clients.Filter
  ---@type LazyFormatter
  local ret = {
    name = "LSP",
    primary = true,
    priority = 1,
    format = function(buf)
      M.format(LazyVim.merge({}, filter, { bufnr = buf }))
    end,
    sources = function(buf)
      local clients = vim.lsp.get_clients(LazyVim.merge({}, filter, { bufnr = buf }))
      ---@param client vim.lsp.Client
      local ret = vim.tbl_filter(function(client)
        return client:supports_method("textDocument/formatting")
          or client:supports_method("textDocument/rangeFormatting")
      end, clients)
      ---@param client vim.lsp.Client
      return vim.tbl_map(function(client)
        return client.name
      end, ret)
    end,
  }
  return LazyVim.merge(ret, opts) --[[@as LazyFormatter]]
end

---@alias lsp.Client.format {timeout_ms?: number, format_options?: table} | vim.lsp.get_clients.Filter

---@param opts? lsp.Client.format
function M.format(opts)
  opts = vim.tbl_deep_extend("force", {}, opts or {}, LazyVim.opts("nvim-lspconfig").format or {})
  local ok, conform = pcall(require, "conform")
  -- 在可用时使用 conform 通过 LSP 进行格式化，
  -- 因为它的格式化差异对比更好
  if ok then
    -- 这里必须是 `nil`，否则不会从 `formatters_by_ft` 中获取选项，
    -- 参见 https://github.com/stevearc/conform.nvim/blob/5420c4b5ea0aeb99c09cfbd4fd0b70d257b44f25/lua/conform/init.lua#L417-L418
    opts.formatters = nil
    conform.format(opts)
  else
    vim.lsp.buf.format(opts)
  end
end

M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler
---@field filter? string|vim.lsp.get_clients.Filter
---@field title? string

---@param opts LspCommand
function M.execute(opts)
  local filter = opts.filter or {}
  filter = type(filter) == "string" and { name = filter } or filter
  local buf = vim.api.nvim_get_current_buf()

  ---@cast filter vim.lsp.get_clients.Filter
  local client = vim.lsp.get_clients(LazyVim.merge({}, filter, { bufnr = buf }))[1]

  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }
  if opts.open then
    require("trouble").open({
      mode = "lsp_command",
      params = params,
    })
  else
    vim.list_extend(params, { title = opts.title })
    return client:exec_cmd(params, { bufnr = buf }, opts.handler)
  end
end

---@param filter? vim.lsp.get_clients.Filter
function M.code_actions(filter)
  filter = filter or {}
  local ret = {} ---@type string[]
  local clients = vim.lsp.get_clients(filter)
  for _, client in ipairs(clients) do
    -- 先检查服务器能力
    vim.list_extend(ret, vim.tbl_get(client, "server_capabilities", "codeActionProvider", "codeActionKinds") or {})
    -- 检查动态能力
    local regs = client.dynamic_capabilities:get("codeActionProvider", filter)
    for _, reg in ipairs(regs or {}) do
      vim.list_extend(ret, vim.tbl_get(reg, "registerOptions", "codeActionKinds") or {})
    end
  end
  return LazyVim.dedup(ret)
end

return M
