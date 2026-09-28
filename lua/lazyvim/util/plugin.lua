local Meta = require("lazy.core.meta")
local Plugin = require("lazy.core.plugin")

---@class lazyvim.util.plugin
local M = {}

---@type string[]
M.core_imports = {}
M.handle_defaults = true

M.lazy_file_events = { "BufReadPost", "BufNewFile", "BufWritePre" }

---@type table<string, string>
M.deprecated_extras = {
  ["lazyvim.plugins.extras.formatting.conform"] = "`conform.nvim` 现已是 **LazyVim** 默认的格式化程序。",
  ["lazyvim.plugins.extras.linting.nvim-lint"] = "`nvim-lint` 现已是 **LazyVim** 默认的代码检查器。",
  ["lazyvim.plugins.extras.ui.dashboard"] = "`dashboard.nvim` 现已是 **LazyVim** 默认的启动界面。",
  ["lazyvim.plugins.extras.coding.native_snippets"] = "**Neovim >= 0.10** 现已默认使用原生代码片段",
  ["lazyvim.plugins.extras.ui.treesitter-rewrite"] = "`treesitter-rewrite` 扩展暂时禁用。尚未准备就绪。",
  ["lazyvim.plugins.extras.ui.treesitter-main"] = "现默认使用 `nvim-treesitter` 的 main 分支",
  ["lazyvim.plugins.extras.coding.mini-ai"] = "`mini.ai` 重新成为 LazyVim 的核心插件",
  ["lazyvim.plugins.extras.lazyrc"] = "本地 spec 文件现已是 lazy.nvim 的特性",
  ["lazyvim.plugins.extras.editor.trouble-v3"] = "Trouble v3 已合并进 main 分支",
  ["lazyvim.plugins.extras.lang.python-semshi"] = [[python-semshi 扩展已被移除，
  因为它引发了太多问题。
  你可以改用 `basedpyright`，或把[旧扩展](https://github.com/LazyVim/LazyVim/blob/c1f5fcf9c7ed2659c9d5ac41b3bb8a93e0a3c6a0/lua/lazyvim/plugins/extras/lang/python-semshi.lua#L1)复制到你自己的配置中。
  ]],
}
M.renamed_extras = {
  ["lazyvim.plugins.extras.lang.omnisharp"] = "lazyvim.plugins.extras.lang.dotnet",
  ["lazyvim.plugins.extras.formatting.biome"] = "lazyvim.plugins.extras.lang.typescript.biome",
  ["lazyvim.plugins.extras.lang.typescript.tsgo"] = "lazyvim.plugins.extras.lang.typescript.tsc",
}

M.deprecated_modules = {}

---@type table<string, string>
M.renames = {
  ["windwp/nvim-spectre"] = "nvim-pack/nvim-spectre",
  ["jose-elias-alvarez/null-ls.nvim"] = "nvimtools/none-ls.nvim",
  ["null-ls.nvim"] = "none-ls.nvim",
  ["romgrk/nvim-treesitter-context"] = "nvim-treesitter/nvim-treesitter-context",
  ["glepnir/dashboard-nvim"] = "nvimdev/dashboard-nvim",
  ["markdown.nvim"] = "render-markdown.nvim",
  ["williamboman/mason.nvim"] = "mason-org/mason.nvim",
  ["williamboman/mason-lspconfig.nvim"] = "mason-org/mason-lspconfig.nvim",
  ["ggandor/leap.nvim"] = "https://codeberg.org/andyg/leap.nvim.git",
}

function M.save_core()
  if vim.v.vim_did_enter == 1 then
    return
  end
  M.core_imports = vim.deepcopy(require("lazy.core.config").spec.modules)
end

function M.setup()
  M.fix_imports()
  M.fix_renames()
  M.lazy_file()
  table.insert(package.loaders, function(module)
    if M.deprecated_modules[module] then
      LazyVim.warn(
        ("`%s` 已不再默认包含在 **LazyVim** 中。\n如果你仍想使用它，请安装 `%s` 扩展。"):format(
          module,
          M.deprecated_modules[module]
        ),
        { title = "LazyVim" }
      )
      return function() end
    end
  end)
end

function M.extra_idx(name)
  local Config = require("lazy.core.config")
  for i, extra in ipairs(Config.spec.modules) do
    if extra == "lazyvim.plugins.extras." .. name then
      return i
    end
  end
end

function M.lazy_file()
  -- 添加对 LazyFile 事件的支持
  local Event = require("lazy.core.handler.event")

  Event.mappings.LazyFile = { id = "LazyFile", event = M.lazy_file_events }
  Event.mappings["User LazyFile"] = Event.mappings.LazyFile
end

function M.fix_imports()
  local defaults ---@type table<string, LazyVimDefault>
  Plugin.Spec.import = LazyVim.inject.args(Plugin.Spec.import, function(_, spec)
    if M.handle_defaults and LazyVim.config.json.loaded then
      -- 扩展被默认配置禁用？
      defaults = defaults or LazyVim.config.get_defaults()
      local def = defaults[spec.import]
      if def and def.enabled == false then
        return false
      end
    end
    local rename = M.renamed_extras[spec.import]
    if rename then
      LazyVim.warn(
        ("扩展 `%s` 已重命名为 `%s`。\n请更新配置中的 `%s`"):format(
          spec.import,
          rename,
          spec.importing or "LazyVim"
        ),
        { title = "LazyVim" }
      )
      spec.import = rename
    end
    local dep = M.deprecated_extras[spec.import]
    if dep then
      dep = dep .. "\n" .. "请从 `lazyvim.json` 中移除该扩展以隐藏此警告。"
      LazyVim.warn(dep, { title = "LazyVim", once = true, stacktrace = true, stacklevel = 6 })
      return false
    end

    local modname = spec.import
    if type(modname) == "string" and vim.startswith(modname, "lazyvim.plugins.extras.") then
      M.single_import(spec)
    end
  end)
end

---@param spec LazySpecImport
function M.single_import(spec)
  local modname = spec.import
  if type(modname) ~= "string" then
    return
  end
  spec.name = modname
  spec.import = function()
    local modinfo = vim.loader.find(modname)[1]
    local modpath = modinfo and modinfo.modpath
    local mod, err = loadfile(modpath)
    if mod then
      local ret, foo = mod()
      if foo then
        return nil, "Spec 模块返回了多个值，但预期只返回一个值。"
      end
      return ret
    else
      return nil, err
    end
  end
end

function M.fix_renames()
  ---@param plugin LazyPluginSpec
  Meta.add = LazyVim.inject.args(Meta.add, function(self, plugin)
    if type(plugin) == "table" then
      local name = plugin[1]
      if not name then
        return
      end
      if name:find("echasnovski") then
        M.renames[name] = name:gsub("echasnovski", "nvim-mini")
      end
      if M.renames[name] then
        LazyVim.warn(
          ("插件 `%s` 已重命名为 `%s`。\n请更新配置中的 `%s`"):format(
            plugin[1],
            M.renames[plugin[1]],
            self.importing or "LazyVim"
          ),
          { title = "LazyVim" }
        )
        plugin[1] = M.renames[name]
      end
    end
  end)
end

return M
