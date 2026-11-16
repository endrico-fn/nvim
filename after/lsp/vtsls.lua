local root_mod = require("util.root")
local ts_mod = require("util.ts")

local global_plugins = {}
local vue_plugin_path =
    root_mod.mason_pkg_path("vue-language-server", "node_modules", "@vue", "typescript-plugin")
if vue_plugin_path then
    table.insert(global_plugins, {
        name = "@vue/typescript-plugin",
        location = vue_plugin_path,
        languages = { "vue" },
        configNamespace = "typescript",
        enableForWorkspaceTypeScriptVersions = true,
    })
end

---@type vim.lsp.Config
return {
    filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
        "vue",
    },
    root_dir = function(bufnr, on_dir)
        -- Yield to native TS 7 `tsc --lsp` when detected (never spawns both)
        if ts_mod.is_ts7_workspace(bufnr).ok then
            return
        end
        local fname = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr) or bufnr
        if not fname or fname == "" then
            return
        end
        local r = root_mod.root_dir(fname, {
            "tsconfig.json",
            "jsconfig.json",
            "package.json",
            ".git",
        })
        on_dir(r or vim.fn.fnamemodify(fname, ":h"))
    end,
    before_init = function(params, config)
        local target = config.root_dir or vim.api.nvim_buf_get_name(0)
        if not target or target == "" then
            return
        end
        local tsdk = root_mod.find_workspace_tsdk(target) or root_mod.vtsls_tsdk()
        if tsdk then
            params.initializationOptions = vim.tbl_deep_extend(
                "force",
                params.initializationOptions or {},
                { typescript = { tsdk = tsdk } }
            )
            config.init_options = params.initializationOptions
        end
    end,
    settings = {
        vtsls = {
            enableMoveToFileCodeAction = true,
            autoUseWorkspaceTsdk = true,
            experimental = {
                completion = { enableServerSideClientsideTelemetry = false },
            },
            diagnostics = { globallyEnabled = true },
            tsserver = {
                globalPlugins = global_plugins,
                maxTsServerMemory = 768,
            },
        },
        typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            preferences = {
                useAliasesForRenames = false,
                renameShorthandProperties = false,
            },
            inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
            },
        },
        javascript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
            },
        },
    },
}
