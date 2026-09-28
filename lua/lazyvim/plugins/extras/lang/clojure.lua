return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = { "clojure", "edn" },
      root = { "project.clj", "deps.edn", "build.boot", "shadow-cljs.edn", "bb.edn" },
    })
  end,

  -- 将 Clojure 及相关内容添加到 treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "clojure" } },
  },

  -- 扩展自动补全
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = {
      "PaterJason/cmp-conjure",
    },
    opts = function(_, opts)
      if type(opts.sources) == "table" then
        vim.list_extend(opts.sources, { name = "conjure" })
      end
    end,
  },

  -- 添加 s-exp 键位映射
  { "julienvincent/nvim-paredit", opts = {}, event = "LazyFile" },

  -- 为日志缓冲区的输出着色
  {
    "m00qek/baleia.nvim",
    opts = {
      line_starts_at = 3,
    },
    config = function(_, opts)
      vim.g.conjure_baleia = require("baleia").setup(opts)

      vim.api.nvim_create_user_command("BaleiaColorize", function()
        vim.g.conjure_baleia.once(vim.api.nvim_get_current_buf())
      end, { bang = true })

      vim.api.nvim_create_user_command("BaleiaLogs", vim.g.conjure_baleia.logger.show, { bang = true })
    end,
  },

  -- 使用 Clojure REPL
  {
    "Olical/conjure",
    event = "LazyFile",
    config = function(_, _)
      require("conjure.main").main()
    end,
    init = function()
      -- 如果 baleia.nvim 可用，则输出颜色代码
      local colorize = require("lazyvim.util").has("baleia.nvim")

      if colorize then
        vim.g["conjure#log#strip_ansi_escape_sequences_line_limit"] = 0
      else
        vim.g["conjure#log#strip_ansi_escape_sequences_line_limit"] = 1
      end

      -- 在日志缓冲区中禁用诊断并为其着色
      vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
        pattern = "conjure-log-*",
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          vim.diagnostic.enable(false, { bufnr = buffer })

          if colorize and vim.g.conjure_baleia then
            vim.g.conjure_baleia.automatically(buffer)
          end

          vim.keymap.set(
            { "n", "x" },
            "[c",
            "<CMD>call search('^; -\\+$', 'bw')<CR>",
            { silent = true, buffer = true, desc = "跳转到上一次求值输出的开头。" }
          )
          vim.keymap.set(
            { "n", "x" },
            "]c",
            "<CMD>call search('^; -\\+$', 'w')<CR>",
            { silent = true, buffer = true, desc = "跳转到下一次求值输出的开头。" }
          )
        end,
      })

      -- 跳转定义和符号文档优先使用 LSP，并使用 conjure
      -- 作为替代方案（<localleader>K 和 <localleader>gd）
      vim.g["conjure#mapping#doc_word"] = "K"
      vim.g["conjure#mapping#def_word"] = "gd"
    end,
  },
}
