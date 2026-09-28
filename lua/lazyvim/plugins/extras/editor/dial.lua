local M = {}

---@param increment boolean
---@param g? boolean
function M.dial(increment, g)
  local mode = vim.fn.mode(true)
  -- 为 VISUAL 'v'、VISUAL LINE 'V' 和 VISUAL BLOCK '\22' 使用可视模式命令
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
  local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
  return require("dial.map")[func](group)
end

return {
  "monaqa/dial.nvim",
  recommended = true,
  desc = "递增和递减数字、日期等",
  -- stylua: ignore
  keys = {
    { "<C-a>", function() return M.dial(true) end, expr = true, desc = "递增", mode = {"n", "v"} },
    { "<C-x>", function() return M.dial(false) end, expr = true, desc = "递减", mode = {"n", "v"} },
    { "g<C-a>", function() return M.dial(true, true) end, expr = true, desc = "递增", mode = {"n", "x"} },
    { "g<C-x>", function() return M.dial(false, true) end, expr = true, desc = "递减", mode = {"n", "x"} },
  },
  opts = function()
    local augend = require("dial.augend")

    local logical_alias = augend.constant.new({
      elements = { "&&", "||" },
      word = false,
      cyclic = true,
    })

    local ordinal_numbers = augend.constant.new({
      -- 循环遍历的元素。递增时向下走，递减时向上走
      elements = {
        "first",
        "second",
        "third",
        "fourth",
        "fifth",
        "sixth",
        "seventh",
        "eighth",
        "ninth",
        "tenth",
      },
      -- 如果为 true，则只匹配带单词边界的字符串。例如 firstDate 不会生效
      word = false,
      -- 是否循环往返（递增时从 tenth 回到 first，递减时从 first 回到 tenth）。
      -- 否则在没有更多值时不会发生任何变化
      cyclic = true,
    })

    local months = augend.constant.new({
      elements = {
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      },
      word = true,
      cyclic = true,
    })

    return {
      dials_by_ft = {
        css = "css",
        vue = "vue",
        javascript = "typescript",
        typescript = "typescript",
        typescriptreact = "typescript",
        javascriptreact = "typescript",
        json = "json",
        lua = "lua",
        markdown = "markdown",
        sass = "css",
        scss = "css",
        python = "python",
      },
      groups = {
        default = {
          augend.integer.alias.decimal, -- nonnegative decimal number (0, 1, 2, 3, ...)
          augend.integer.alias.decimal_int, -- nonnegative and negative decimal number
          augend.integer.alias.hex, -- nonnegative hex number  (0x01, 0x1a1f, etc.)
          augend.date.alias["%Y/%m/%d"], -- date (2022/02/19, etc.)
          augend.constant.alias.en_weekday, -- Mon, Tue, ..., Sat, Sun
          augend.constant.alias.en_weekday_full, -- Monday, Tuesday, ..., Saturday, Sunday
          ordinal_numbers,
          months,
          augend.constant.alias.bool, -- boolean value (true <-> false)
          augend.constant.alias.Bool, -- boolean value (True <-> False)
          logical_alias,
        },
        vue = {
          augend.constant.new({ elements = { "let", "const" } }),
          augend.hexcolor.new({ case = "lower" }),
          augend.hexcolor.new({ case = "upper" }),
        },
        typescript = {
          augend.constant.new({ elements = { "let", "const" } }),
        },
        css = {
          augend.hexcolor.new({
            case = "lower",
          }),
          augend.hexcolor.new({
            case = "upper",
          }),
        },
        markdown = {
          augend.constant.new({
            elements = { "[ ]", "[x]" },
            word = false,
            cyclic = true,
          }),
          augend.misc.alias.markdown_header,
        },
        json = {
          augend.semver.alias.semver, -- versioning (v1.1.2)
        },
        lua = {
          augend.constant.new({
            elements = { "and", "or" },
            word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
            cyclic = true, -- "or" is incremented into "and".
          }),
        },
        python = {
          augend.constant.new({
            elements = { "and", "or" },
          }),
        },
      },
    }
  end,
  config = function(_, opts)
    -- 将默认值复制到每个分组
    for name, group in pairs(opts.groups) do
      if name ~= "default" then
        vim.list_extend(group, opts.groups.default)
      end
    end
    require("dial.config").augends:register_group(opts.groups)
    vim.g.dials_by_ft = opts.dials_by_ft
  end,
}
