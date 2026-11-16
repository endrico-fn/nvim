---@type vim.lsp.Config
return {
    init_options = {
        includeLanguages = {
            astro = "html",
            svelte = "html",
            vue = "html",
            ["javascript.jsx"] = "javascriptreact",
            ["typescript.tsx"] = "typescriptreact",
        },
        showAbbreviationSuggestions = true,
        showExpandedAbbreviation = "always",
        showSuggestionsAsSnippets = true,
    },
}
