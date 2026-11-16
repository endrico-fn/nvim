---@type vim.lsp.Config
return {
    filetypes = { "json", "jsonc", "json5" },
    before_init = function(_, config)
        local ok, schemastore = pcall(require, "schemastore")
        if not ok then
            return
        end
        config.settings = config.settings or {}
        config.settings.json = config.settings.json or {}
        config.settings.json.schemas = config.settings.json.schemas or {}
        vim.list_extend(config.settings.json.schemas, schemastore.json.schemas())
    end,
    settings = {
        json = {
            format = { enable = false },
            validate = { enable = true },
        },
    },
}
