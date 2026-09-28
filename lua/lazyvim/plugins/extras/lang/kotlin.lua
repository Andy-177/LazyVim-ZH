return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "kotlin",
      root = {
        "settings.gradle", -- Gradle（多项目）
        "settings.gradle.kts", -- Gradle（多项目）
        "build.xml", -- Ant
        "pom.xml", -- Maven
        "build.gradle", -- Gradle
        "build.gradle.kts", -- Gradle
      },
    })
  end,
  -- 添加软件包（代码检查、调试适配器）
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "ktlint" } },
  },
  -- 添加语法高亮
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "kotlin" } },
  },
  -- 添加语言服务器
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {},
      },
    },
  },
  -- 添加代码检查
  {
    "mfussenegger/nvim-lint",
    optional = true,
    dependencies = "mason-org/mason.nvim",
    opts = {
      linters_by_ft = { kotlin = { "ktlint" } },
    },
  },
  -- 添加格式化
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = { kotlin = { "ktlint" } },
    },
  },
  -- 添加格式化和代码检查
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.formatting.ktlint,
        nls.builtins.diagnostics.ktlint,
      })
    end,
  },
  -- 添加调试器
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = "mason-org/mason.nvim",
    opts = function()
      local dap = require("dap")
      if not dap.adapters.kotlin then
        dap.adapters.kotlin = {
          type = "executable",
          command = "kotlin-debug-adapter",
          options = { auto_continue_if_many_stopped = false },
        }
      end

      dap.configurations.kotlin = {
        {
          type = "kotlin",
          request = "launch",
          name = "This file",
          -- 可能不同，无论如何，如果对你的项目结构有疑问，
          -- 它必须对应位于 `build/classes/` 下的 class 文件
          -- 当然，调试前必须先构建
          mainClass = function()
            local root = vim.fs.find("src", { path = vim.uv.cwd(), upward = true, stop = vim.env.HOME })[1] or ""
            local fname = vim.api.nvim_buf_get_name(0)
            -- src/main/kotlin/websearch/Main.kt -> websearch.MainKt
            return fname:gsub(root, ""):gsub("main/kotlin/", ""):gsub(".kt", "Kt"):gsub("/", "."):sub(2, -1)
          end,
          projectRoot = "${workspaceFolder}",
          jsonLogFile = "",
          enableJsonLogging = false,
        },
        {
          -- 将其用于单元测试
          -- 首先，运行
          -- ./gradlew --info cleanTest test --debug-jvm
          -- 然后将调试器附加到它
          type = "kotlin",
          request = "attach",
          name = "Attach to debugging session",
          port = 5005,
          args = {},
          projectRoot = vim.fn.getcwd,
          hostName = "localhost",
          timeout = 2000,
        },
      }
    end,
  },
}
