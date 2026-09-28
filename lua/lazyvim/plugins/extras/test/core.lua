return {
  recommended = true,
  desc = "Neotest 支持，需要配置特定语言的适配器（参见 lang 扩展）",
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio" },
    opts = {
      -- 可以是 neotest 期望的适配器列表，
      -- 也可以是适配器名称的列表，
      -- 也可以是「适配器名称 -> 适配器配置」的映射表。
      -- 适配器随后会自动带上该配置加载。
      adapters = {},
      -- 使用自定义配置加载 neotest-golang 的示例
      -- adapters = {
      --   ["neotest-golang"] = {
      --     go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
      --     dap_go_enabled = true,
      --   },
      -- },
      status = { virtual_text = true },
      output = { open_on_run = true },
      quickfix = {
        open = function()
          if LazyVim.has("trouble.nvim") then
            require("trouble").open({ mode = "quickfix", focus = false })
          else
            vim.cmd("copen")
          end
        end,
      },
    },
    config = function(_, opts)
      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            -- 把换行符和制表符替换为空格，让诊断信息更紧凑
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, neotest_ns)

      if LazyVim.has("trouble.nvim") then
        opts.consumers = opts.consumers or {}
        -- 运行测试后刷新并自动关闭 trouble
        ---@type neotest.Consumer
        opts.consumers.trouble = function(client)
          client.listeners.results = function(adapter_id, results, partial)
            if partial then
              return
            end
            local tree = assert(client:get_position(nil, { adapter = adapter_id }))

            local failed = 0
            for pos_id, result in pairs(results) do
              if result.status == "failed" and tree:get_key(pos_id) then
                failed = failed + 1
              end
            end
            vim.schedule(function()
              local trouble = require("trouble")
              if trouble.is_open() then
                trouble.refresh()
                if failed == 0 then
                  trouble.close()
                end
              end
            end)
            return {}
          end
        end
      end

      if opts.adapters then
        local adapters = {}
        for name, config in pairs(opts.adapters or {}) do
          if type(name) == "number" then
            if type(config) == "string" then
              config = require(config)
            end
            adapters[#adapters + 1] = config
          elseif config ~= false then
            local adapter = require(name)
            if type(config) == "table" and not vim.tbl_isempty(config) then
              local meta = getmetatable(adapter)
              if adapter.setup then
                adapter.setup(config)
              elseif adapter.adapter then
                adapter.adapter(config)
                adapter = adapter.adapter
              elseif meta and meta.__call then
                adapter = adapter(config)
              else
                error("Adapter " .. name .. " does not support setup")
              end
            end
            adapters[#adapters + 1] = adapter
          end
        end
        opts.adapters = adapters
      end

      require("neotest").setup(opts)
    end,
    -- stylua: ignore
    keys = {
      {"<leader>t", "", desc = "+test"},
      { "<leader>ta", function() require("neotest").run.attach() end, desc = "附加到测试 (Neotest)" },
      { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "运行文件 (Neotest)" },
      { "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "运行全部测试文件 (Neotest)" },
      { "<leader>tr", function() require("neotest").run.run() end, desc = "运行最近的测试 (Neotest)" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "运行上一个测试 (Neotest)" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "切换摘要 (Neotest)" },
      { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "显示输出 (Neotest)" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "切换输出面板 (Neotest)" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "停止 (Neotest)" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "切换监听 (Neotest)" },
    },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    -- stylua: ignore
    keys = {
      { "<leader>td", function() require("neotest").run.run({strategy = "dap"}) end, desc = "调试最近的测试" },
    },
  },
}
