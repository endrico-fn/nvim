---@type vim.lsp.Config
return {
    before_init = function(_, config)
        local ok, schemastore = pcall(require, "schemastore")
        if not ok then
            return
        end
        config.settings = config.settings or {}
        config.settings.yaml = config.settings.yaml or {}
        config.settings.yaml.schemas = vim.tbl_deep_extend(
            "force",
            config.settings.yaml.schemas or {},
            schemastore.yaml.schemas()
        )
    end,
    settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
            keyOrdering = false,
            format = { enable = false },
            validate = true,
            completion = true,
            schemaStore = { enable = false, url = "" },
            customTags = {
                "!reference sequence",
                "!secret scalar",
                "!vault scalar",
                "!vault sequence",
                "!vault mapping",
                "!include scalar",
                "!include mapping",
                "!extends scalar",
                "!extends mapping",
                "!binary scalar",
            },
        },
    },
}
