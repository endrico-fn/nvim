---@type vim.lsp.Config
return {
    settings = {
        svelte = {
            plugin = {
                svelte = { defaultScriptLanguage = "ts" },
                typescript = { diagnostics = { enable = true } },
                css = { diagnostics = { enable = true } },
            },
        },
    },
}
