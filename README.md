# lsp-actiononsave.nvim

NeoVim Lua plugin that performs LSP code actions and code formatting when saving files

## Installation

### Lazy.nvim

```lua
{
    "takagiy/lsp-actiononsave.nvim",
    opts = {},
}
```

## Configuration

```lua
opts = {
    -- Enable notifications
    verbose = true,
    -- Table of LSP servers
    servers = {
        -- Server name
        biome = {
            -- Table of actions to perform
            "format",
            "codeAction/source.organizeImports",
            "codeAction/source.fixAll",
        },
        -- Function that takes a filetype and returns a table of actions to perform
        ["null-ls"] = function(ft)
            if ft == "lua" then
                return { "format" }
            end
            return {}
        end,
    },
}
```
