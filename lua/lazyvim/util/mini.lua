---@class lazyvim.util.mini
local M = {}

-- 取自 MiniExtra.gen_ai_spec.buffer
function M.ai_buffer(ai_type)
  local start_line, end_line = 1, vim.fn.line("$")
  if ai_type == "i" then
    -- 对 `i` 文本对象，跳过首尾的空行
    local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
    -- 对于全为空白字符的缓冲区不做任何处理
    if first_nonblank == 0 or last_nonblank == 0 then
      return { from = { line = start_line, col = 1 } }
    end
    start_line, end_line = first_nonblank, last_nonblank
  end

  local to_col = math.max(vim.fn.getline(end_line):len(), 1)
  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end

-- 向 which-key 注册所有文本对象
---@param opts table
function M.ai_whichkey(opts)
  local objects = {
    { " ", desc = "空白字符" },
    { '"', desc = '" 字符串' },
    { "'", desc = "' 字符串" },
    { "(", desc = "() 块" },
    { ")", desc = "() 块（含空白）" },
    { "<", desc = "<> 块" },
    { ">", desc = "<> 块（含空白）" },
    { "?", desc = "用户提示符" },
    { "U", desc = "不带点的 use/call" },
    { "[", desc = "[] 块" },
    { "]", desc = "[] 块（含空白）" },
    { "_", desc = "下划线" },
    { "`", desc = "` 字符串" },
    { "a", desc = "参数" },
    { "b", desc = ")]} 块" },
    { "c", desc = "类" },
    { "d", desc = "数字" },
    { "e", desc = "CamelCase / snake_case" },
    { "f", desc = "函数" },
    { "g", desc = "整个文件" },
    { "i", desc = "缩进块" },
    { "o", desc = "块、条件语句、循环" },
    { "q", desc = "引号 `\"'" },
    { "t", desc = "标签" },
    { "u", desc = "use/call" },
    { "{", desc = "{} 块" },
    { "}", desc = "{} 块（含空白）" },
  }

  ---@type wk.Spec[]
  local ret = { mode = { "o", "x" } }
  ---@type table<string, string>
  local mappings = vim.tbl_extend("force", {}, {
    around = "a",
    inside = "i",
    around_next = "an",
    inside_next = "in",
    around_last = "al",
    inside_last = "il",
  }, opts.mappings or {})
  mappings.goto_left = nil
  mappings.goto_right = nil

  for name, prefix in pairs(mappings) do
    name = name:gsub("^around_", ""):gsub("^inside_", "")
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc
      if prefix:sub(1, 1) == "i" then
        desc = desc:gsub(" with ws", "")
      end
      ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
    end
  end
  require("which-key").add(ret, { notify = false })
end

---@param opts {skip_next: string, skip_ts: string[], skip_unbalanced: boolean, markdown: boolean}
function M.pairs(opts)
  Snacks.toggle({
    name = "Mini Pairs",
    get = function()
      return not vim.g.minipairs_disable
    end,
    set = function(state)
      vim.g.minipairs_disable = not state
    end,
  }):map("<leader>up")

  local pairs = require("mini.pairs")
  pairs.setup(opts)
  local open = pairs.open
  pairs.open = function(pair, neigh_pattern)
    if vim.fn.getcmdline() ~= "" then
      return open(pair, neigh_pattern)
    end
    local o, c = pair:sub(1, 1), pair:sub(2, 2)
    local line = vim.api.nvim_get_current_line()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local next = line:sub(cursor[2] + 1, cursor[2] + 1)
    local before = line:sub(1, cursor[2])
    if opts.markdown and o == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
      return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
    end
    if opts.skip_next and next ~= "" and next:match(opts.skip_next) then
      return o
    end
    if opts.skip_ts and #opts.skip_ts > 0 then
      local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
      for _, capture in ipairs(ok and captures or {}) do
        if vim.tbl_contains(opts.skip_ts, capture.capture) then
          return o
        end
      end
    end
    if opts.skip_unbalanced and next == c and c ~= o then
      local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
      local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")
      if count_close > count_open then
        return o
      end
    end
    return open(pair, neigh_pattern)
  end
end

return M
