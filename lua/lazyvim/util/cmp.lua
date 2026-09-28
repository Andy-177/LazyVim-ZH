---@class lazyvim.util.cmp
local M = {}

---@alias lazyvim.util.cmp.Action fun():boolean?
---@type table<string, lazyvim.util.cmp.Action>
M.actions = {
  -- 原生代码片段
  snippet_forward = function()
    if vim.snippet.active({ direction = 1 }) then
      vim.schedule(function()
        vim.snippet.jump(1)
      end)
      return true
    end
  end,
  snippet_stop = function()
    if vim.snippet then
      vim.snippet.stop()
    end
  end,
}

---@param actions string[]
---@param fallback? string|fun()
function M.map(actions, fallback)
  return function()
    for _, name in ipairs(actions) do
      if M.actions[name] then
        local ret = M.actions[name]()
        if ret then
          return true
        end
      end
    end
    return type(fallback) == "function" and fallback() or fallback
  end
end

---@alias Placeholder {n:number, text:string}

---@param snippet string
---@param fn fun(placeholder:Placeholder):string
---@return string
function M.snippet_replace(snippet, fn)
  return snippet:gsub("%$%b{}", function(m)
    local n, name = m:match("^%${(%d+):(.+)}$")
    return n and fn({ n = n, text = name }) or m
  end) or snippet
end

-- 该函数用于解析代码片段中嵌套的占位符。
---@param snippet string
---@return string
function M.snippet_preview(snippet)
  local ok, parsed = pcall(function()
    return vim.lsp._snippet_grammar.parse(snippet)
  end)
  return ok and tostring(parsed)
    or M.snippet_replace(snippet, function(placeholder)
      return M.snippet_preview(placeholder.text)
    end):gsub("%$0", "")
end

-- 该函数用 LSP 占位符替换代码片段中嵌套的占位符。
function M.snippet_fix(snippet)
  local texts = {} ---@type table<number, string>
  return M.snippet_replace(snippet, function(placeholder)
    texts[placeholder.n] = texts[placeholder.n] or M.snippet_preview(placeholder.text)
    return "${" .. placeholder.n .. ":" .. texts[placeholder.n] .. "}"
  end)
end

---@param entry cmp.Entry
function M.auto_brackets(entry)
  local cmp = require("cmp")
  local Kind = cmp.lsp.CompletionItemKind
  local item = entry:get_completion_item()
  if vim.tbl_contains({ Kind.Function, Kind.Method }, item.kind) then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local prev_char = vim.api.nvim_buf_get_text(0, cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1, {})[1]
    if prev_char ~= "(" and prev_char ~= ")" then
      local keys = vim.api.nvim_replace_termcodes("()<left>", false, false, true)
      vim.api.nvim_feedkeys(keys, "i", true)
    end
  end
end

-- 该函数为代码片段补充缺失的文档。
-- 该文档是代码片段的预览。
---@param window cmp.CustomEntriesView|cmp.NativeEntriesView
function M.add_missing_snippet_docs(window)
  local cmp = require("cmp")
  local Kind = cmp.lsp.CompletionItemKind
  local entries = window:get_entries()
  for _, entry in ipairs(entries) do
    if entry:get_kind() == Kind.Snippet then
      local item = entry:get_completion_item()
      if not item.documentation and item.insertText then
        item.documentation = {
          kind = cmp.lsp.MarkupKind.Markdown,
          value = string.format("```%s\n%s\n```", vim.bo.filetype, M.snippet_preview(item.insertText)),
        }
      end
    end
  end
end

-- 这是对 `cmp.confirm` 更好的实现：
--  * 无需等待正在运行的数据源即可检查补全菜单是否可见
--  * 在确认前创建一个撤销点
-- 该实现既更快也更可靠。
---@param opts? {select: boolean, behavior: cmp.ConfirmBehavior}
function M.confirm(opts)
  local cmp = require("cmp")
  opts = vim.tbl_extend("force", {
    select = true,
    behavior = cmp.ConfirmBehavior.Insert,
  }, opts or {})
  return function(fallback)
    if cmp.core.view:visible() or vim.fn.pumvisible() == 1 then
      LazyVim.create_undo()
      if cmp.confirm(opts) then
        return
      end
    end
    return fallback()
  end
end

function M.expand(snippet)
  -- 原生会话不支持嵌套的代码片段会话。
  -- 始终使用最顶层的会话。
  -- 否则，当光标位于第一个占位符并选择新的补全项时，
  -- 将会使用嵌套会话而非顶层会话。
  -- 参见：https://github.com/LazyVim/LazyVim/issues/3199
  local session = vim.snippet.active() and vim.snippet._session or nil

  local ok, err = pcall(vim.snippet.expand, snippet)
  if not ok then
    local fixed = M.snippet_fix(snippet)
    ok = pcall(vim.snippet.expand, fixed)

    local msg = ok and "无法解析代码片段，\n但已自动修复。"
      or ("无法解析代码片段。\n" .. err)

    LazyVim[ok and "warn" or "error"](
      ([[%s
```%s
%s
```]]):format(msg, vim.bo.filetype, snippet),
      { title = "vim.snippet" }
    )
  end

  -- 必要时恢复顶层会话
  if session then
    vim.snippet._session = session
  end
end

---@param opts cmp.ConfigSchema | {auto_brackets?: string[]}
function M.setup(opts)
  for _, source in ipairs(opts.sources) do
    source.group_index = source.group_index or 1
  end

  local parse = require("cmp.utils.snippet").parse
  require("cmp.utils.snippet").parse = function(input)
    local ok, ret = pcall(parse, input)
    if ok then
      return ret
    end
    return LazyVim.cmp.snippet_preview(input)
  end

  local cmp = require("cmp")
  cmp.setup(opts)
  cmp.event:on("confirm_done", function(event)
    if vim.tbl_contains(opts.auto_brackets or {}, vim.bo.filetype) then
      LazyVim.cmp.auto_brackets(event.entry)
    end
  end)
  cmp.event:on("menu_opened", function(event)
    LazyVim.cmp.add_missing_snippet_docs(event.window)
  end)
end

return M
