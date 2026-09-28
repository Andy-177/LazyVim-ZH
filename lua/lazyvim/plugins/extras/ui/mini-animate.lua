-- 动画
return {
  -- 启用 animate 时禁用 snacks scroll
  {
    "snacks.nvim",
    opts = {
      scroll = { enabled = false },
    },
  },

  -- 为许多常见的 Neovim 操作添加动画，比如滚动、
  -- 移动光标和调整窗口大小。
  {
    "nvim-mini/mini.animate",
    event = "VeryLazy",
    cond = vim.g.neovide == nil,
    opts = function(_, opts)
      -- 使用鼠标滚动时不要用 animate
      local mouse_scrolled = false
      for _, scroll in ipairs({ "Up", "Down" }) do
        local key = "<ScrollWheel" .. scroll .. ">"
        vim.keymap.set({ "", "i" }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "grug-far",
        callback = function()
          vim.b.minianimate_disable = true
        end,
      })

      -- 延后设置映射，以覆盖 `keymaps.lua` 中的默认映射
      -- 似乎 `keymaps.lua` 是 `VeryLazy` 中最后执行的事件，会覆盖它
      vim.schedule(function()
        Snacks.toggle({
          name = "Mini Animate",
          get = function()
            return not vim.g.minianimate_disable
          end,
          set = function(state)
            vim.g.minianimate_disable = not state
          end,
        }):map("<leader>ua")
      end)

      local animate = require("mini.animate")
      return vim.tbl_deep_extend("force", opts, {
        resize = {
          timing = animate.gen_timing.linear({ duration = 50, unit = "total" }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
          subscroll = animate.gen_subscroll.equal({
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          }),
        },
      })
    end,
  },
}
