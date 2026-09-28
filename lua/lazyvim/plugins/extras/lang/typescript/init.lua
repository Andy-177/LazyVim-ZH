if lazyvim_docs then
  -- 用于 TypeScript 的 LSP 服务器。
  ---@type "vtsls" | "tsgo"
  vim.g.lazyvim_ts_lsp = "vtsls" -- 当前默认值

  -- 若要使用更新、更快的 `tsc` LSP 服务器，可以：
  -- * 启用 `tsc` extra，或
  -- * 在你的 `options.lua` 中设置 `vim.g.lazyvim_ts_lsp = "tsc"`
end

-- 目前将已弃用的 `tsgo` 改为 `tsc`，因为在 TS7 中 `tsgo` == `tsc`
if vim.g.lazyvim_ts_lsp == "tsgo" then
  vim.g.lazyvim_ts_lsp = "tsc"
end

local extra = LazyVim.config.register_defaults("ts_lsp", {
  { name = "vtsls", extra = "lang.typescript.vtsls" },
  { name = "tsc", extra = "lang.typescript.tsc" },
})

return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
      },
      root = { "tsconfig.json", "package.json", "jsconfig.json" },
    })
  end,

  { import = extra.import },

  -- 正确配置 lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local lsp = extra.name or "vtsls"
      local servers = { "tsserver", "ts_ls", "vtsls", "tsc", lsp }
      for _, server in ipairs(servers) do
        opts.servers[server] = opts.servers[server] or {}
        opts.servers[server].enabled = server == lsp
      end
    end,
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          table.insert(opts.ensure_installed, "js-debug-adapter")
        end,
      },
    },
    opts = function()
      local dap = require("dap")

      for _, adapterType in ipairs({ "node", "chrome", "msedge" }) do
        local pwaType = "pwa-" .. adapterType

        if not dap.adapters[pwaType] then
          dap.adapters[pwaType] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
              command = "js-debug-adapter",
              args = { "${port}" },
            },
          }
        end

        -- 为了兼容 VSCode，定义不带 "pwa-" 前缀的 adapter
        if not dap.adapters[adapterType] then
          dap.adapters[adapterType] = function(cb, config)
            local nativeAdapter = dap.adapters[pwaType]

            config.type = pwaType

            if type(nativeAdapter) == "function" then
              nativeAdapter(cb, config)
            else
              cb(nativeAdapter)
            end
          end
        end
      end

      local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

      local vscode = require("dap.ext.vscode")
      vscode.type_to_filetypes["node"] = js_filetypes
      vscode.type_to_filetypes["pwa-node"] = js_filetypes

      for _, language in ipairs(js_filetypes) do
        if not dap.configurations[language] then
          local runtimeExecutable = nil
          if language:find("typescript") then
            runtimeExecutable = vim.fn.executable("tsx") == 1 and "tsx" or "ts-node"
          end
          dap.configurations[language] = {
            {
              type = "pwa-node",
              request = "launch",
              name = "Launch file",
              program = "${file}",
              cwd = "${workspaceFolder}",
              sourceMaps = true,
              runtimeExecutable = runtimeExecutable,
              skipFiles = {
                "<node_internals>/**",
                "node_modules/**",
              },
              resolveSourceMapLocations = {
                "${workspaceFolder}/**",
                "!**/node_modules/**",
              },
            },
            {
              type = "pwa-node",
              request = "attach",
              name = "Attach",
              processId = require("dap.utils").pick_process,
              cwd = "${workspaceFolder}",
              sourceMaps = true,
              runtimeExecutable = runtimeExecutable,
              skipFiles = {
                "<node_internals>/**",
                "node_modules/**",
              },
              resolveSourceMapLocations = {
                "${workspaceFolder}/**",
                "!**/node_modules/**",
              },
            },
          }
        end
      end
    end,
  },

  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = {
      -- chrome adapter 已弃用，请改用 js-debug-adapter
      automatic_installation = { exclude = { "chrome" } },
    },
  },

  -- 文件类型图标
  {
    "nvim-mini/mini.icons",
    opts = {
      file = {
        [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
        [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
        [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
        ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
      },
    },
  },
}
