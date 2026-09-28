local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error
local info = vim.health.info or vim.health.report_info

function M.check()
  start("LazyVim")

  if vim.fn.has("nvim-0.11.2") == 1 then
    ok("正在使用 Neovim >= 0.11.2")
  else
    error("需要 Neovim >= 0.11.2")
  end

  for _, cmd in ipairs({ "git", "rg", { "fd", "fdfind" }, "lazygit", "fzf", "curl" }) do
    local name = type(cmd) == "string" and cmd or vim.inspect(cmd)
    local commands = type(cmd) == "string" and { cmd } or cmd
    ---@cast commands string[]
    local found = false

    for _, c in ipairs(commands) do
      if vim.fn.executable(c) == 1 then
        name = c
        found = true
      end
    end

    if found then
      ok(("`%s` 已安装"):format(name))
    else
      warn(("`%s` 未安装"):format(name))
    end
  end

  start("LazyVim nvim-treesitter")
  local tsok, health = LazyVim.treesitter.check()
  local keys = vim.tbl_keys(health) ---@type string[]
  table.sort(keys)
  for _, k in pairs(keys) do
    (health[k] and ok or error)("`%s` %s"):format(k, health[k] and "已安装" or "未安装")
  end
  if not tsok then
    info(
      "请查看 [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter/tree/main?tab=readme-ov-file#requirements) 中的依赖要求"
    )
    info("运行 `:checkhealth nvim-treesitter` 查看更多信息。")
    if vim.fn.has("win32") == 1 and not health["C 编译器"] then
      info("使用 `winget install --id=BrechtSanders.WinLibs.POSIX.UCRT -e` 安装 C 编译器")
    end
  end
end

return M
