---@type vim.lsp.Config
return {
    filetypes = { "html", "jsp" },
    settings = {
        css = { validate = true },
        javascript = { format = { enable = false } },
    },
}
