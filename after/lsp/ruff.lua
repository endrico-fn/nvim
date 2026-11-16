---@type vim.lsp.Config
return {
    on_attach = function(client, _)
        if client.name == "ruff" then
            -- Type checking/hover lives with basedpyright/ty; formatting runs through conform
            client.server_capabilities.hoverProvider = false
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
        end
    end,
}
