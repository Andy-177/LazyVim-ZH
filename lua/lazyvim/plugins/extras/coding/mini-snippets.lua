if lazyvim_docs then
  -- 设为 `false` 可防止 "non-lsp snippets"" 出现在补全窗口中
  -- 初衷：减少补全窗口中的杂乱内容，让代码片段使用起来更直接
  vim.g.lazyvim_mini_snippets_in_completion = true

  -- 注意：请同时阅读：
  -- https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-snippets.md#expand
  -- :h MiniSnippets-session

  -- 覆盖为你自己配置的示例：
  --[[
  return {
    {
      "nvim-mini/mini.snippets",
      opts = function(_, opts)
        -- 默认情况下，对于 opts.snippets，mini.snippets 扩展只添加 gen_loader.from_lang()
        -- 这提供了一个合理的快速上手方案，并集成了 friendly-snippets
        -- 以及你自己语言特定的代码片段
        --
        -- 若要修改 opts.snippets，请在自己的 opts 中替换整个表

        local snippets, config_path = require("mini.snippets"), vim.fn.stdpath("config")

        opts.snippets = { -- override opts.snippets provided by extra...
          -- 先加载包含全局代码片段的自定义文件（顺序很重要）
          snippets.gen_loader.from_file(config_path .. "/snippets/global.json"),

          -- 从 'runtimepath' 目录下的子目录读取文件，
          -- 根据当前语言加载 "snippets/" 代码片段
          snippets.gen_loader.from_lang(), -- this is the default in the extra...
        }
      end,
    },
  }
--]]
end

local include_in_completion = vim.g.lazyvim_mini_snippets_in_completion == nil
  or vim.g.lazyvim_mini_snippets_in_completion

local function expand_from_lsp(snippet)
  local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
  insert({ body = snippet })
end

local function jump(direction)
  local is_active = MiniSnippets.session.get(false) ~= nil
  if is_active then
    MiniSnippets.session.jump(direction)
    return true
  end
end

---@type fun(snippets, insert) | nil
local expand_select_override = nil

return {
  -- 禁用内置代码片段支持：
  { "garymjr/nvim-snippets", optional = true, enabled = false },
  -- 禁用 luasnip：
  { "L3MON4D3/LuaSnip", optional = true, enabled = false },

  -- 添加 mini.snippets
  desc = "管理和展开代码片段（Luasnip 的替代品）",
  {
    "nvim-mini/mini.snippets",
    event = "InsertEnter", -- don't depend on other plugins to load...
    dependencies = "rafamadriz/friendly-snippets",
    opts = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      LazyVim.cmp.actions.snippet_stop = function() end -- by design, <esc> should not stop the session!
      ---@diagnostic disable-next-line: duplicate-set-field
      LazyVim.cmp.actions.snippet_forward = function()
        return jump("next")
      end

      local mini_snippets = require("mini.snippets")
      return {
        snippets = { mini_snippets.gen_loader.from_lang() },

        -- 沿用 vim.snippets 的行为，
        -- <esc> 的预期用法是能临时回到普通模式进行快速编辑。
        --
        -- 如果你更想用 <esc> 结束代码片段，请在自己的配置中启用下面这行：
        -- mappings = { stop = "<esc>" }, -- 默认是 <c-c>，参见 :h MiniSnippets-session

        expand = {
          select = function(snippets, insert)
            -- 选择代码片段时关闭补全窗口 —— vim.ui.select
            -- 需要为 fzf-lua 和 telescope 移除虚拟文本，但 mini.pick 不需要...
            local select = expand_select_override or MiniSnippets.default_select
            select(snippets, insert)
          end,
        },
      }
    end,
  },

  -- nvim-cmp 集成
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = include_in_completion and { "abeldekat/cmp-mini-snippets" } or nil,
    opts = function(_, opts)
      local cmp = require("cmp")
      local cmp_config = require("cmp.config")

      opts.snippet = {
        expand = function(args)
          expand_from_lsp(args.body)
          cmp.resubscribe({ "TextChangedI", "TextChangedP" })
          cmp_config.set_onetime({ sources = {} })
        end,
      }

      if include_in_completion then
        table.insert(opts.sources, { name = "mini_snippets" })
      else
        expand_select_override = function(snippets, insert)
          -- stylua: ignore
          if cmp.visible() then cmp.close() end
          MiniSnippets.default_select(snippets, insert)
        end
      end
    end,
    -- stylua: ignore
    -- 与 cmp.mappings 中定义的 <tab> 相对应
    keys = include_in_completion and { { "<s-tab>", function() jump("prev") end, mode = "i" } } or nil,
  },

  -- blink.cmp 集成
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      -- 提前返回
      if include_in_completion then
        opts.snippets = { preset = "mini_snippets" }
        return
      end

      -- 独立模式 --
      local blink = require("blink.cmp")
      expand_select_override = function(snippets, insert)
        -- 需要 schedule，否则 vim.ui.select 时 blink 的虚拟文本不会被移除
        blink.cancel()
        vim.schedule(function()
          MiniSnippets.default_select(snippets, insert)
        end)
      end
      --
      -- Blink 会对 blink.cmp.sources.snippets.default 执行 require
      -- 移除该数据源后，就不会使用那个默认引擎
      opts.sources.default = vim.tbl_filter(function(source)
        return source ~= "snippets"
      end, opts.sources.default)
      opts.snippets = { -- need to repeat blink's preset here
        expand = function(snippet)
          expand_from_lsp(snippet)
          blink.resubscribe()
        end,
        active = function()
          return MiniSnippets.session.get(false) ~= nil
        end,
        jump = function(direction)
          jump(direction == -1 and "prev" or "next")
        end,
      }
    end,
  },
}
