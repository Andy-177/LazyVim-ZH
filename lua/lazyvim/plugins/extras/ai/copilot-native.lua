---@diagnostic disable: missing-fields
if lazyvim_docs then
  -- 原生内联补全不支持作为常规补全显示
  vim.g.ai_cmp = false
end

if LazyVim.has_extra("ai.copilot-native") then
  if vim.fn.has("nvim-0.12") == 0 then
    LazyVim.error("使用 `ai.copilot-native` 扩展需要 Neovim >= 0.12。")
    return {}
  end
  if LazyVim.has_extra("ai.copilot") then
    LazyVim.error("如果想使用 `ai.copilot-native`，请先禁用 `ai.copilot` 扩展")
    return {}
  end
end

vim.g.ai_cmp = false
local status = {} ---@type table<number, "ok" | "error" | "pending">

return {
  desc = "原生 Copilot LSP 集成，需要 Neovim >= 0.12",
  -- copilot-language-server
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        copilot = {
          -- stylua: ignore
          keys = {
            {
              "<M-]>",
              function() vim.lsp.inline_completion.select({ count = 1 }) end,
              desc = "下一个 Copilot 建议",
              mode = { "i", "n" },
            },
            {
              "<M-[>",
              function() vim.lsp.inline_completion.select({ count = -1 }) end,
              desc = "上一个 Copilot 建议",
              mode = { "i", "n" },
            },
          },
        },
      },
      setup = {
        copilot = function()
          vim.schedule(function()
            vim.lsp.inline_completion.enable()
          end)
          -- 接受内联建议或后续编辑
          LazyVim.cmp.actions.ai_accept = function()
            return vim.lsp.inline_completion.get()
          end

          if not LazyVim.has_extra("ai.sidekick") then
            vim.lsp.config("copilot", {
              handlers = {
                didChangeStatus = function(err, res, ctx)
                  if err then
                    return
                  end
                  status[ctx.client_id] = res.kind ~= "Normal" and "error" or res.busy and "pending" or "ok"
                  if res.status == "Error" then
                    LazyVim.error("请使用 `:LspCopilotSignIn` 登录 Copilot")
                  end
                end,
              },
            })
          end
        end,
      },
    },
  },

  -- lualine
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    opts = function(_, opts)
      if LazyVim.has_extra("ai.sidekick") then
        return
      end
      table.insert(
        opts.sections.lualine_x,
        2,
        LazyVim.lualine.status(LazyVim.config.icons.kinds.Copilot, function()
          local clients = vim.lsp.get_clients({ name = "copilot", bufnr = 0 })
          return #clients > 0 and status[clients[1].id] or nil
        end)
      )
    end,
  },
}
