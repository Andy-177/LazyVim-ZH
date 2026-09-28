---@class lazyvim.util.terminal
local M = {}

---@param shell? string
function M.setup(shell)
  vim.o.shell = shell or vim.o.shell

  -- 对 pwsh 的特殊处理
  if shell == "pwsh" or shell == "powershell" then
    -- 检查 'pwsh' 是否可执行，并据此设置 shell
    if vim.fn.executable("pwsh") == 1 then
      vim.o.shell = "pwsh"
    elseif vim.fn.executable("powershell") == 1 then
      vim.o.shell = "powershell"
    else
      return LazyVim.error("未找到 powershell 可执行文件")
    end

    -- 设置 shell 命令标志
    vim.o.shellcmdflag =
      "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();$PSDefaultParameterValues['Out-File:Encoding']='utf8';$PSStyle.OutputRendering='plaintext';Remove-Alias -Force -ErrorAction SilentlyContinue tee;"

    -- 设置 shell 重定向
    vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'

    -- 设置 shell 管道
    vim.o.shellpipe = '2>&1 | %%{ "$_" } | tee %s; exit $LastExitCode'

    -- 设置 shell 引号选项
    vim.o.shellquote = ""
    vim.o.shellxquote = ""
  end
end

return M
