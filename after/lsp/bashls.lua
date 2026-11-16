---@type vim.lsp.Config
return {
    root_markers = { ".git", ".srcpx-state.json", "AGENTS.md", "Makefile" },
    settings = {
        bashIde = {
            -- Shellcheck runs via nvim-lint; disable duplicate built-in bashls shellcheck
            shellcheckPath = "",
        },
    },
}
