-- 这与 lspconfig.configs.jdtls 中的做法相同，但避免了
-- 在加载此模块时 require 它。
local java_filetypes = { "java" }

-- 用于扩展或覆盖配置表的工具函数，类似于
-- Plugin.opts 的工作方式。
---@param config table
---@param custom function | table | nil
local function extend_or_override(config, custom, ...)
  if type(custom) == "function" then
    config = custom(config, ...) or config
  elseif custom then
    config = vim.tbl_deep_extend("force", config, custom) --[[@as table]]
  end
  return config
end

return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "java",
      root = {
        "build.gradle",
        "build.gradle.kts",
        "build.xml", -- Ant
        "pom.xml", -- Maven
        "settings.gradle", -- Gradle
        "settings.gradle.kts", -- Gradle
      },
    })
  end,

  -- 将 java 添加到 treesitter。
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "java" } },
  },

  -- 确保已安装 java 调试器和测试包。
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      -- 用于附加到远程 java 调试进程的简单配置
      -- 直接取自 https://github.com/mfussenegger/nvim-dap/wiki/Java
      local dap = require("dap")
      dap.configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Debug (Attach) - Remote",
          hostName = "127.0.0.1",
          port = 5005,
        },
      }
    end,
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = { ensure_installed = { "java-debug-adapter", "java-test" } },
      },
    },
  },

  -- 配置 nvim-lspconfig 通过 mason 自动安装服务器，但
  -- 将实际启动推迟到下面我们对 nvim-jtdls 的配置中。
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- 确保 mason 安装该服务器
      servers = {
        jdtls = {},
      },
      setup = {
        jdtls = function()
          return true -- avoid duplicate servers
        end,
      },
    },
  },

  -- 配置 nvim-jdtls 以附加到 java 文件。
  {
    "mfussenegger/nvim-jdtls",
    dependencies = { "folke/which-key.nvim" },
    ft = java_filetypes,
    opts = function()
      local cmd = { vim.fn.exepath("jdtls") }
      if LazyVim.has("mason.nvim") then
        local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
        table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
      end
      return {
        root_dir = function(path)
          return vim.fs.root(path, vim.lsp.config.jdtls.root_markers)
        end,

        -- 如何为给定的根目录找到项目名称。
        project_name = function(root_dir)
          return root_dir and vim.fs.basename(root_dir)
        end,

        -- 项目的 config 和 workspace 目录在哪里？
        jdtls_config_dir = function(project_name)
          return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
        end,
        jdtls_workspace_dir = function(project_name)
          return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
        end,

        -- 如何运行 jdtls。如果 Python 包装脚本不够用，
        -- 可以将其覆盖为完整的 java 命令行。
        cmd = cmd,
        full_cmd = function(opts)
          local fname = vim.api.nvim_buf_get_name(0)
          local root_dir = opts.root_dir(fname)
          local project_name = opts.project_name(root_dir)
          local cmd = vim.deepcopy(opts.cmd)
          if project_name then
            vim.list_extend(cmd, {
              "-configuration",
              opts.jdtls_config_dir(project_name),
              "-data",
              opts.jdtls_workspace_dir(project_name),
            })
          end
          return cmd
        end,

        -- 这些依赖 nvim-dap，但也可以通过在此处设为 false 来额外禁用。
        dap = { hotcodereplace = "auto", config_overrides = {} },
        -- 可以设为 false 以禁用主类扫描，这对大型项目影响性能很大
        dap_main = {},
        test = true,
        settings = {
          java = {
            inlayHints = {
              parameterNames = {
                enabled = "all",
              },
            },
          },
        },
      }
    end,
    config = function(_, opts)
      -- 查找应该传递给 jdtls 命令行的额外 bundle
      -- 当 nvim-dap 启用了 java 调试/测试时。
      local bundles = {} ---@type string[]
      if LazyVim.has("mason.nvim") then
        local mason_registry = require("mason-registry")
        if opts.dap and LazyVim.has("nvim-dap") and mason_registry.is_installed("java-debug-adapter") then
          bundles = vim.fn.glob("$MASON/share/java-debug-adapter/com.microsoft.java.debug.plugin-*jar", false, true)
          -- java-test 还依赖 java-debug-adapter。
          if opts.test and mason_registry.is_installed("java-test") then
            vim.list_extend(bundles, vim.fn.glob("$MASON/share/java-test/*.jar", false, true))
          end
        end
      end
      local function attach_jdtls()
        local fname = vim.api.nvim_buf_get_name(0)

        -- 配置可以通过 opts.jdtls 补充和覆盖
        local config = extend_or_override({
          cmd = opts.full_cmd(opts),
          root_dir = opts.root_dir(fname),
          init_options = {
            bundles = bundles,
          },
          settings = opts.settings,
          -- 启用 CMP 能力
          capabilities = LazyVim.has("blink.cmp") and require("blink.cmp").get_lsp_capabilities() or LazyVim.has(
            "cmp-nvim-lsp"
          ) and require("cmp_nvim_lsp").default_capabilities() or nil,
        }, opts.jdtls)

        -- 如果 root_dir 匹配，将复用已有的服务器。
        require("jdtls").start_or_attach(config)
        -- 不需要 require("jdtls.setup").add_commands()，start 会自动添加命令
      end

      -- 为每个 java 缓冲区附加 jdtls。但是，此插件是
      -- 根据文件类型加载的，因此该 autocmd 不会为第一个文件触发。
      -- 为此，我们在下面直接调用。
      vim.api.nvim_create_autocmd("FileType", {
        pattern = java_filetypes,
        callback = attach_jdtls,
      })

      -- 在 lsp 完全附加后设置键位和 dap。
      -- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
      -- https://neovim.io/doc/user/lsp.html#LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "jdtls" then
            local wk = require("which-key")
            wk.add({
              {
                mode = "n",
                buffer = args.buf,
                { "<leader>cx", group = "extract" },
                { "<leader>cxv", require("jdtls").extract_variable_all, desc = "提取变量" },
                { "<leader>cxc", require("jdtls").extract_constant, desc = "提取常量" },
                { "<leader>cgs", require("jdtls").super_implementation, desc = "转到父类" },
                { "<leader>cgS", require("jdtls.tests").goto_subjects, desc = "转到主题" },
                { "<leader>co", require("jdtls").organize_imports, desc = "整理导入" },
              },
            })
            wk.add({
              {
                mode = "x",
                buffer = args.buf,
                { "<leader>cx", group = "extract" },
                {
                  "<leader>cxm",
                  [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
                  desc = "提取方法",
                },
                {
                  "<leader>cxv",
                  [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
                  desc = "提取变量",
                },
                {
                  "<leader>cxc",
                  [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
                  desc = "提取常量",
                },
              },
            })

            if LazyVim.has("mason.nvim") then
              local mason_registry = require("mason-registry")
              if opts.dap and LazyVim.has("nvim-dap") and mason_registry.is_installed("java-debug-adapter") then
                -- Java 调试器的自定义初始化
                require("jdtls").setup_dap(opts.dap)
                if opts.dap_main then
                  require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)
                end

                -- Java 测试需要 Java 调试器才能工作
                if opts.test and mason_registry.is_installed("java-test") then
                  -- Java 测试运行器的自定义键位（尚不兼容 neotest）
                  wk.add({
                    {
                      mode = "n",
                      buffer = args.buf,
                      { "<leader>t", group = "test" },
                      {
                        "<leader>tt",
                        function()
                          require("jdtls.dap").test_class({
                            config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides or nil,
                          })
                        end,
                        desc = "运行全部测试",
                      },
                      {
                        "<leader>tr",
                        function()
                          require("jdtls.dap").test_nearest_method({
                            config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides or nil,
                          })
                        end,
                        desc = "运行最近的测试",
                      },
                      { "<leader>tT", require("jdtls.dap").pick_test, desc = "运行测试" },
                    },
                  })
                end
              end
            end

            -- 用户可以在 opts.on_attach 中设置额外的键位
            if opts.on_attach then
              opts.on_attach(args)
            end
          end
        end,
      })

      -- 由于 autocmd 不会触发，首次直接调用 attach 以避免竞态条件。
      attach_jdtls()
    end,
  },
}
