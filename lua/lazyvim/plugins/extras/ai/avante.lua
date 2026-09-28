return {
  { "MunifTanjim/nui.nvim", lazy = true },

  {
    "yetone/avante.nvim",
    build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    event = "VeryLazy",
    opts = {
      provider = "copilot",
      selection = {
        hint_display = "none",
      },
      behaviour = {
        auto_set_keymaps = false,
      },
    },
    cmd = {
      "AvanteAsk",
      "AvanteBuild",
      "AvanteChat",
      "AvanteClear",
      "AvanteEdit",
      "AvanteFocus",
      "AvanteHistory",
      "AvanteModels",
      "AvanteRefresh",
      "AvanteShowRepoMap",
      "AvanteStop",
      "AvanteSwitchProvider",
      "AvanteToggle",
    },
    keys = {
      { "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "向 Avante 提问" },
      { "<leader>ac", "<cmd>AvanteChat<CR>", desc = "与 Avante 对话" },
      { "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "Avante 编辑" },
      { "<leader>af", "<cmd>AvanteFocus<CR>", desc = "聚焦 Avante" },
      { "<leader>ah", "<cmd>AvanteHistory<CR>", desc = "Avante 历史" },
      { "<leader>am", "<cmd>AvanteModels<CR>", desc = "选择 Avante 模型" },
      { "<leader>an", "<cmd>AvanteChatNew<CR>", desc = "新建 Avante 对话" },
      { "<leader>ap", "<cmd>AvanteSwitchProvider<CR>", desc = "切换 Avante 提供方" },
      { "<leader>ar", "<cmd>AvanteRefresh<CR>", desc = "刷新 Avante" },
      { "<leader>as", "<cmd>AvanteStop<CR>", desc = "停止 Avante" },
      { "<leader>at", "<cmd>AvanteToggle<CR>", desc = "切换 Avante" },
    },
  },

  -- 支持粘贴图片
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    optional = true,
    opts = {
      -- 推荐设置
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
        -- Windows 用户必需
        use_absolute_path = true,
      },
    },
  },

  -- 如果你使用 lazy=true，请确保正确配置此项
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    opts = {
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "Avante" },
  },

  -- avante.nvim 的 blink.cmp 数据源
  {
    "saghen/blink.cmp",
    optional = true,
    specs = { "Kaiser-Yang/blink-cmp-avante" },
    opts = {
      sources = {
        default = { "avante" },
        providers = { avante = { module = "blink-cmp-avante", name = "Avante" } },
      },
    },
  },
}
