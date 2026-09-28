return {
  -- 禁用 gitsigns.nvim
  {
    "lewis6991/gitsigns.nvim",
    enabled = false,
  },

  -- 配置 mini.diff
  {
    "nvim-mini/mini.diff",
    event = "VeryLazy",
    keys = {
      {
        "<leader>go",
        function()
          require("mini.diff").toggle_overlay(0)
        end,
        desc = "切换 mini.diff 浮层",
      },
    },
    opts = {
      view = {
        style = "sign",
        signs = {
          add = "▎",
          change = "▎",
          delete = "",
        },
      },
    },
  },
  {
    "mini.diff",
    opts = function()
      Snacks.toggle({
        name = "Mini Diff Signs",
        get = function()
          return vim.g.minidiff_disable ~= true
        end,
        set = function(state)
          vim.g.minidiff_disable = not state
          if state then
            require("mini.diff").enable(0)
          else
            require("mini.diff").disable(0)
          end
          -- HACK：重绘以更新符号标记
          vim.defer_fn(function()
            vim.cmd([[redraw!]])
          end, 200)
        end,
      }):map("<leader>uG")
    end,
  },

  -- lualine 集成
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local x = opts.sections.lualine_x
      for _, comp in ipairs(x) do
        if comp[1] == "diff" then
          comp.source = function()
            local summary = vim.b.minidiff_summary
            return summary
              and {
                added = summary.add,
                modified = summary.change,
                removed = summary.delete,
              }
          end
          break
        end
      end
    end,
  },
}
