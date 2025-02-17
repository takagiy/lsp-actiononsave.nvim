# lsp-actiononsave.nvim

NeoVim Lua plugin that performs LSP code actions and code formatting when saving files

![](https://github.com/user-attachments/assets/326ebe1b-005c-48ef-a832-8c5628eaeff9)


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
    -- Table of language servers
    servers = {
        -- Server name
        ts_ls = {
            -- Table of actions to perform
            "format",
            "codeAction/source.organizeImports",
            "codeAction/source.fixAll",
        },
        biome = {
            "format",
            "codeAction/source.organizeImports",
            "codeAction/source.fixAll",
            -- Skip some other language servers if this server is active (optional. string or table of strings)
            skip = "ts_ls",
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
