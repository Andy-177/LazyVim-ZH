-- 自动高亮光标下单词的其他出现位置。
-- 通过 LSP、Treesitter 和正则匹配来查找其他出现位置。
return {
  -- 禁用 snacks words
  { "snacks.nvim", opts = { words = { enabled = false } } },

  {
    "RRethy/vim-illuminate",
    event = "LazyFile",
    opts = {
      delay = 200,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { "lsp" },
      },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)

      Snacks.toggle({
        name = "Illuminate",
        get = function()
          return not require("illuminate.engine").is_paused()
        end,
        set = function(enabled)
          local m = require("illuminate")
          if enabled then
            m.resume()
          else
            m.pause()
          end
        end,
      }):map("<leader>ux")

      local function map(key, dir, buffer)
        vim.keymap.set("n", key, function()
          require("illuminate")["goto_" .. dir .. "_reference"](false)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
      end

      map("]]", "next")
      map("[[", "prev")

      -- 在加载 ftplugins 之后也要设置，因为很多插件会覆盖 [[ 和 ]]
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map("]]", "next", buffer)
          map("[[", "prev", buffer)
        end,
      })
    end,
    keys = {
      { "]]", desc = "下一个引用" },
      { "[[", desc = "上一个引用" },
    },
  },
}
