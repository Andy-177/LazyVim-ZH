return {
  -- lspconfig
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      { "mason-org/mason-lspconfig.nvim", config = function() end },
    },
    opts_extend = { "servers.*.keys" },
    opts = function()
      ---@class PluginLspOpts
      local ret = {
        -- vim.diagnostic.config() 的选项
        ---@type vim.diagnostic.Opts
        diagnostics = {
          underline = true,
          update_in_insert = false,
          virtual_text = {
            spacing = 4,
            source = "if_many",
            prefix = "●",
            -- 这会将前缀设置为根据严重程度返回诊断图标的函数
            -- prefix = "icons",
          },
          severity_sort = true,
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
              [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
              [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
              [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
            },
          },
        },
        -- 启用此项可在 Neovim 中开启内置的 LSP 内联提示。
        -- 请注意，你还需要正确配置 LSP 服务器以
        -- 提供内联提示。
        inlay_hints = {
          enabled = true,
          exclude = { "vue" }, -- 不希望启用内联提示的文件类型
        },
        -- 启用此项可在 Neovim 中开启内置的 LSP 代码透镜。
        -- 请注意，你还需要正确配置 LSP 服务器以
        -- 提供代码透镜。
        codelens = {
          enabled = false,
        },
        -- 启用此项可在 Neovim 中开启内置的 LSP 折叠。
        -- 请注意，你还需要正确配置 LSP 服务器以
        -- 提供折叠信息。
        folds = {
          enabled = true,
        },
        -- vim.lsp.buf.format 的选项
        -- `bufnr` 和 `filter` 由 LazyVim 格式化程序处理，
        -- 但在显式指定时也可以覆盖
        format = {
          formatting_options = nil,
          timeout_ms = nil,
        },
        -- LSP 服务器设置
        -- 设置 LSP 客户端的默认配置（若使用特殊名称 "*" 则适用于所有客户端）。
        ---@alias lazyvim.lsp.Config vim.lsp.Config|{mason?:boolean, enabled?:boolean, keys?:LazyKeysLspSpec[]}
        ---@type table<string, lazyvim.lsp.Config|boolean>
        servers = {
          -- 所有 LSP 服务器的配置
          ["*"] = {
            capabilities = {
              workspace = {
                fileOperations = {
                  didRename = true,
                  willRename = true,
                },
              },
            },
            -- stylua: ignore
            keys = {
              { "<leader>cl", function() Snacks.picker.lsp_config() end, desc = "LSP 信息" },
              { "gd", vim.lsp.buf.definition, desc = "跳转到定义", has = "definition" },
              { "gr", vim.lsp.buf.references, desc = "查找引用", nowait = true },
              { "gI", vim.lsp.buf.implementation, desc = "跳转到实现" },
              { "gy", vim.lsp.buf.type_definition, desc = "跳转到类型定义" },
              { "gD", vim.lsp.buf.declaration, desc = "跳转到声明" },
              { "K", function() return vim.lsp.buf.hover() end, desc = "悬停信息" },
              { "gK", function() return vim.lsp.buf.signature_help() end, desc = "函数签名帮助", has = "signatureHelp" },
              { "<c-k>", function() return vim.lsp.buf.signature_help() end, mode = "i", desc = "函数签名帮助", has = "signatureHelp" },
              { "<leader>ca", vim.lsp.buf.code_action, desc = "代码操作", mode = { "n", "x" }, has = "codeAction" },
              { "<leader>cc", vim.lsp.codelens.run, desc = "运行代码透镜", mode = { "n", "x" }, has = "codeLens" },
              { "<leader>cC", vim.lsp.codelens.refresh, desc = "刷新并显示代码透镜", mode = { "n" }, has = "codeLens" },
              { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "重命名文件", mode ={"n"}, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
              { "<leader>cr", vim.lsp.buf.rename, desc = "重命名", has = "rename" },
              { "<leader>cA", LazyVim.lsp.action.source, desc = "源代码操作", has = "codeAction" },
              { "]]", function() Snacks.words.jump(vim.v.count1) end, has = "documentHighlight",
                desc = "下一处引用", enabled = function() return Snacks.words.is_enabled() end },
              { "[[", function() Snacks.words.jump(-vim.v.count1) end, has = "documentHighlight",
                desc = "上一处引用", enabled = function() return Snacks.words.is_enabled() end },
              { "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, has = "documentHighlight",
                desc = "下一处引用", enabled = function() return Snacks.words.is_enabled() end },
              { "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, has = "documentHighlight",
                desc = "上一处引用", enabled = function() return Snacks.words.is_enabled() end },
              {
                "<leader>co",
                LazyVim.lsp.action["source.organizeImports"],
                desc = "整理导入",
                has = "codeAction",
                enabled = function(buf)
                  local code_actions = vim.tbl_filter(function(action)
                    return action:find("^source%.organizeImports%.?$")
                  end, LazyVim.lsp.code_actions({ bufnr = buf }))
                  return #code_actions > 0
                end
              },
            },
          },
          stylua = { enabled = false },
          lua_ls = {
            -- mason = false, -- 如果不希望通过 mason 安装该服务器，可设为 false
            -- 你可以用它为特定 LSP 服务器
            -- 添加额外的键位
            -- ---@type LazyKeysSpec[]
            -- keys = {},
            settings = {
              Lua = {
                workspace = {
                  checkThirdParty = false,
                },
                codeLens = {
                  enable = true,
                },
                completion = {
                  callSnippet = "Replace",
                },
                doc = {
                  privateName = { "^_" },
                },
                hint = {
                  enable = true,
                  setType = false,
                  paramType = true,
                  paramName = "Disable",
                  semicolon = "Disable",
                  arrayIndex = "Disable",
                },
              },
            },
          },
        },
        -- 你可以在这里进行任何额外的 LSP 服务器设置
        -- 如果不希望该服务器由 lspconfig 配置，请返回 true
        ---@type table<string, fun(server:string, opts: vim.lsp.Config):boolean?>
        setup = {
          -- 使用 typescript.nvim 进行配置的示例
          -- tsserver = function(_, opts)
          --   require("typescript").setup({ server = opts })
          --   return true
          -- end,
          -- 指定 * 可将该函数用作任意服务器的兜底
          -- ["*"] = function(server, opts) end,
        },
      }
      return ret
    end,
    ---@param opts PluginLspOpts
    config = function(_, opts)
      -- 配置自动格式化
      LazyVim.format.register(LazyVim.lsp.formatter())

      -- 配置键位
      local names = vim.tbl_keys(opts.servers) ---@type string[]
      table.sort(names)
      for _, server in ipairs(names) do
        local server_opts = opts.servers[server]
        if type(server_opts) == "table" and server_opts.keys then
          require("lazyvim.plugins.lsp.keymaps").set({ name = server ~= "*" and server or nil }, server_opts.keys)
        end
      end

      -- 内联提示
      if opts.inlay_hints.enabled then
        Snacks.util.lsp.on({ method = "textDocument/inlayHint" }, function(buffer)
          if
            vim.api.nvim_buf_is_valid(buffer)
            and vim.bo[buffer].buftype == ""
            and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[buffer].filetype)
          then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
          end
        end)
      end

      -- 折叠
      if opts.folds.enabled then
        Snacks.util.lsp.on({ method = "textDocument/foldingRange" }, function()
          if LazyVim.set_default("foldmethod", "expr") then
            LazyVim.set_default("foldexpr", "v:lua.vim.lsp.foldexpr()")
          end
        end)
      end

      -- 代码透镜
      if opts.codelens.enabled and vim.lsp.codelens then
        Snacks.util.lsp.on({ method = "textDocument/codeLens" }, function(buffer)
          vim.lsp.codelens.refresh()
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = buffer,
            callback = vim.lsp.codelens.refresh,
          })
        end)
      end

      -- 诊断
      if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
        opts.diagnostics.virtual_text.prefix = function(diagnostic)
          local icons = LazyVim.config.icons.diagnostics
          for d, icon in pairs(icons) do
            if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
              return icon
            end
          end
          return "●"
        end
      end
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      if opts.capabilities then
        LazyVim.deprecate("lsp-config.opts.capabilities", "请改用 lsp-config.opts.servers['*'].capabilities")
        opts.servers["*"] = vim.tbl_deep_extend("force", opts.servers["*"] or {}, {
          capabilities = opts.capabilities,
        })
      end

      if opts.servers["*"] then
        vim.lsp.config("*", opts.servers["*"])
      end

      -- 获取所有可通过 mason-lspconfig 获得的服务器
      local have_mason = LazyVim.has("mason-lspconfig.nvim")
      local mason_all = have_mason
          and vim.tbl_keys(require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package)
        or {} --[[ @as string[] ]]
      local mason_exclude = {} ---@type string[]

      ---@return boolean? 返回 true 以排除自动配置
      local function configure(server)
        if server == "*" then
          return false
        end
        local sopts = opts.servers[server]
        sopts = sopts == true and {} or (not sopts) and { enabled = false } or sopts --[[@as lazyvim.lsp.Config]]

        if sopts.enabled == false then
          mason_exclude[#mason_exclude + 1] = server
          return
        end

        local use_mason = sopts.mason ~= false and vim.tbl_contains(mason_all, server)
        local setup = opts.setup[server] or opts.setup["*"]
        if setup and setup(server, sopts) then
          mason_exclude[#mason_exclude + 1] = server
        else
          vim.lsp.config(server, sopts) -- 配置该服务器
          if not use_mason then
            vim.lsp.enable(server)
          end
        end
        return use_mason
      end

      local install = vim.tbl_filter(configure, vim.tbl_keys(opts.servers))
      if have_mason then
        require("mason-lspconfig").setup({
          ensure_installed = vim.list_extend(install, LazyVim.opts("mason-lspconfig.nvim").ensure_installed or {}),
          automatic_enable = { exclude = mason_exclude },
        })
      end
    end,
  },

  -- 命令行工具和 LSP 服务器
  {

    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
      },
    },
    ---@param opts MasonSettings | {ensure_installed: string[]}
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- 触发 FileType 事件，以便加载这个新安装的 LSP 服务器
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
}
