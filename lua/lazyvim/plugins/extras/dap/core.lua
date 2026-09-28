---@param config {type?:string, args?:string[]|fun():string[]?}
local function get_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {} --[[@as string[] | string ]]
  local args_str = type(args) == "table" and table.concat(args, " ") or args --[[@as string]]

  config = vim.deepcopy(config)
  ---@cast args string[]
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input("Run with args: ", args_str)) --[[@as string]]
    if config.type and config.type == "java" then
      ---@diagnostic disable-next-line: return-type-mismatch
      return new_args
    end
    return require("dap.utils").splitstr(new_args)
  end
  return config
end

return {
  {
    "mfussenegger/nvim-dap",
    recommended = true,
    desc = "调试支持，需要配置特定语言的适配器（参见 lang 扩展）",

    dependencies = {
      "rcarriga/nvim-dap-ui",
      -- 调试器的虚拟文本
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    },

    -- stylua: ignore
    keys = {
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('断点条件：')) end, desc = "断点条件" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "切换断点" },
      { "<leader>dc", function() require("dap").continue() end, desc = "运行/继续" },
      { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "带参数运行" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "运行到光标处" },
      { "<leader>dg", function() require("dap").goto_() end, desc = "转到行（不执行）" },
      { "<leader>di", function() require("dap").step_into() end, desc = "单步进入" },
      { "<leader>dj", function() require("dap").down() end, desc = "向下" },
      { "<leader>dk", function() require("dap").up() end, desc = "向上" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "运行上一个" },
      { "<leader>do", function() require("dap").step_out() end, desc = "单步跳出" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "单步跳过" },
      { "<leader>dP", function() require("dap").pause() end, desc = "暂停" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "切换 REPL" },
      { "<leader>ds", function() require("dap").session() end, desc = "会话" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "终止" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "组件" },
    },

    config = function()
      -- 在所有适配器配置完成之后，于此处加载 mason-nvim-dap
      if LazyVim.has("mason-nvim-dap.nvim") then
        require("mason-nvim-dap").setup(LazyVim.opts("mason-nvim-dap.nvim"))
      end

      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(LazyVim.config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end

      -- 通过 VsCode 的 launch.json 文件配置 dap
      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end
    end,
  },

  -- 调试器的高颜值界面
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap 界面" },
      { "<leader>de", function() require("dapui").eval() end, desc = "求值", mode = {"n", "x"} },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },

  -- mason.nvim 集成
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = "mason.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      -- 尽力为各种调试器设置
      -- 合理的调试配置
      automatic_installation = true,

      -- 你可以向 handlers 提供额外的配置，
      -- 更多信息请参阅 mason-nvim-dap 的 README
      handlers = {},

      -- 你需要确认所需的东西已经安装
      -- 在线安装，别问我怎么装 :)
      ensure_installed = {
        -- 更新此项以确保拥有你所需语言的调试器
      },
    },
    -- nvim-dap 加载时会同时加载 mason-nvim-dap
    config = function() end,
  },
}
