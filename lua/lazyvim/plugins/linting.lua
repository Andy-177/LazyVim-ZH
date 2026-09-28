return {
  -- 异步调用特定语言的代码检查工具，并通过 `vim.diagnostic` 模块
  -- 上报结果。
  {
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
      -- 触发代码检查的事件
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        fish = { "fish" },
        -- 使用 "*" 文件类型可以对所有文件类型运行代码检查。
        -- ['*'] = { 'global linter' },
        -- 使用 "_" 文件类型可以对未配置其它代码检查的文件类型运行代码检查。
        -- ['_'] = { 'fallback linter' },
        -- ["*"] = { "typos" },
      },
      -- LazyVim 扩展，便于覆盖代码检查器选项
      -- 或添加自定义代码检查器。
      ---@type table<string,table>
      linters = {
        -- -- 示例：仅在存在 selene.toml 文件时使用 selene
        -- selene = {
        --   -- `condition` 是另一个 LazyVim 扩展，允许你
        --   -- 根据上下文动态启用/禁用代码检查器。
        --   condition = function(ctx)
        --     return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
        --   end,
        -- },
      },
    },
    config = function(_, opts)
      local M = {}

      local function list_prepend(dst, src)
        for i = 1, #src do
          table.insert(dst, i, src[i])
        end
      end

      local lint = require("lint")
      for name, linter in pairs(opts.linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
          if type(linter.prepend_args) == "table" then
            lint.linters[name].args = lint.linters[name].args or {}
            list_prepend(lint.linters[name].args, linter.prepend_args)
          end
        else
          lint.linters[name] = linter
        end
      end
      lint.linters_by_ft = opts.linters_by_ft

      function M.debounce(ms, fn)
        local timer = vim.uv.new_timer()
        return function(...)
          local argv = { ... }
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
          end)
        end
      end

      function M.lint()
        -- 优先使用 nvim-lint 的逻辑：
        -- * 先检查完整文件类型是否存在对应的代码检查器
        -- * 否则按 "." 拆分文件类型，并添加所有这些代码检查器
        -- * 这与 conform.nvim 不同，后者只使用第一个带格式化程序的文件类型
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)

        -- 复制名称表，避免修改原始表。
        names = vim.list_extend({}, names)

        -- 添加兜底的代码检查器。
        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft["_"] or {})
        end

        -- 添加全局代码检查器。
        vim.list_extend(names, lint.linters_by_ft["*"] or {})

        -- 过滤掉不存在的或不满足条件的代码检查器。
        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter then
            LazyVim.warn("未找到代码检查器：" .. name, { title = "nvim-lint" })
          end
          return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
        end, names)

        -- 运行代码检查器。
        if #names > 0 then
          lint.try_lint(names)
        end
      end

      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = M.debounce(100, M.lint),
      })
    end,
  },
}
