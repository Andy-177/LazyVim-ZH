# 为 LazyVim 贡献代码

## 总体准则

- 尽可能避免使用 Vim 插件。
- 如果某个 extra 必须依赖 Vim 插件，请在 PR 描述中说明原因。
- 确保所有配置都可以通过 Lazy 的 spec 被用户覆盖。
- 对于仅在用户已安装时才应启用的 spec，标记为 `optional`。
- 为 extra 中添加的每个插件实现正确的懒加载。
- 理解 Lazy 的依赖机制。对于 Lua 依赖，不要在 `dependencies` 字段中声明，
  而应将其作为独立的 spec 添加，并设置 `lazy=true`。

## 贡献 extra 插件

- 该插件应当足够知名，并且需要大量配置。
- 仅包含插件本身加少量选项的简单 spec 不会被接受。

## 贡献 extra 语言

- 你应当熟悉所要添加的这门语言。
- 你应当了解该语言的生态，包括格式化工具、代码检查工具和 LSP 服务器。
- 该 extra 应当包含社区中广泛使用的配置。
- 包含尚未默认启用的 Tree-sitter 语法解析器。
- 包含最常用的 LSP 服务器配置。
- 尽可能避免依赖 LSP 封装包。
- 只有当社区通常使用独立格式化工具而非 LSP 内置格式化时，才添加格式化工具。
- 只有当社区通常使用额外的代码检查工具而不仅依赖 LSP 内置检查时，才添加额外的代码检查工具。
- 每个语言 extra 都必须包含一个 `recommended` 部分。
  查看 lspconfig 中的服务器配置，以确定正确的文件类型和根目录。
  `recommended` 部分的写法可参考其他 extra。

### 语言专用键位映射

- 语言专用键位映射使用 `<localleader>`（遵循 Vim/Neovim 针对特定文件类型映射的惯例）。
- 对于 LSP 服务器，请在服务器的 `keys` 字段中定义键位映射，而不是在 `on_attach` 中：
  ```lua
  servers = {
    rust_analyzer = {
      keys = {
        { "<localleader>e", function() vim.cmd.RustLsp("expandMacro") end, desc = "Expand Macro" },
      }
    }
  }
  ```
- LazyVim 的 LSP 系统会自动解析并应用这些键位映射（参见 `lua/lazyvim/plugins/lsp/keymaps.lua`）。
- 除非绝对必要，否则不要覆盖标准的 LSP 键位映射（例如 `K` 用于悬浮窗口、`gd` 用于跳转定义）。
- 在合适的地方使用标准的 `<leader>c*` 键位映射（例如用 `<leader>co` 触发整理导入）。
- 正确使用 `<localleader>` 的示例请参考 R 和 Haskell 这两个 extra。
