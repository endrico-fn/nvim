---@type vim.lsp.Config
return {
    init_options = {
        diagnosticSeverity = "Hint",
    },
    before_init = function(params, config)
        local search_path = config.root_dir
        if not search_path or search_path == "" then
            local fname = vim.api.nvim_buf_get_name(0)
            search_path = fname ~= "" and vim.fs.dirname(fname) or vim.uv.cwd()
        end
        local project_cfg = vim.fs.find(
            { ".typos.toml", "typos.toml", "_typos.toml" },
            { path = search_path, upward = true }
        )[1]
        if not project_cfg then
            local global_cfg = vim.fs.joinpath(vim.fn.stdpath("config"), ".typos.toml")
            params.initializationOptions = vim.tbl_deep_extend(
                "force",
                params.initializationOptions or {},
                { config = global_cfg }
            )
            config.init_options = params.initializationOptions
        end
    end,
}
