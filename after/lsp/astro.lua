---@type vim.lsp.Config
return {
    init_options = {
        typescript = {},
    },
    before_init = function(params, config)
        local root_mod = require("util.root")
        local candidates = {}
        if config.root_dir and config.root_dir ~= "" then
            table.insert(candidates, config.root_dir)
        end
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname and bufname ~= "" then
            table.insert(candidates, bufname)
        end
        table.insert(candidates, vim.fn.getcwd())

        local tsdk
        for _, fname in ipairs(candidates) do
            tsdk = root_mod.find_workspace_tsdk(fname)
            if tsdk then
                break
            end
        end
        tsdk = tsdk or root_mod.vtsls_tsdk()
        if tsdk then
            params.initializationOptions = vim.tbl_deep_extend(
                "force",
                params.initializationOptions or {},
                { typescript = { tsdk = tsdk } }
            )
            config.init_options = params.initializationOptions
        end
    end,
}
