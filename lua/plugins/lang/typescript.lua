local lsp = require("core.lsp")

return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}

            opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
                filetypes = {
                    "javascript",
                    "javascriptreact",
                    "javascript.jsx",
                    "typescript",
                    "typescriptreact",
                },
                root_dir = function(bufnr, on_dir)
                    local fname = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr)
                        or bufnr
                    if fname == "" then
                        on_dir(nil)
                        return
                    end
                    local root = require("core.root")
                    local r = root.root_dir(fname, {
                        "tsconfig.json",
                        "jsconfig.json",
                        "package.json",
                        ".git",
                    })
                    on_dir(r or vim.fn.fnamemodify(fname, ":h"))
                end,
                on_new_config = function(new_config, new_root)
                    -- tsdk harus di-set SEBELUM server start (init_options).
                    -- Mutasi via on_attach tidak berefek sampai restart server.
                    local fname = new_root or vim.api.nvim_buf_get_name(0)
                    if fname == "" then
                        return
                    end
                    local tsdk = require("core.root").find_workspace_tsdk(fname)
                    if tsdk then
                        new_config.init_options =
                            vim.tbl_deep_extend("force", new_config.init_options or {}, {
                                typescript = { tsdk = tsdk },
                            })
                    end
                end,
                keys = {
                    {
                        "gD",
                        function()
                            local win = vim.api.nvim_get_current_win()
                            local params = vim.lsp.util.make_position_params(win, "utf-16")
                            lsp.execute({
                                command = "typescript.goToSourceDefinition",
                                arguments = { params.textDocument.uri, params.position },
                                open = true,
                            })
                        end,
                        "Goto Source Definition",
                        has = "textDocument/definition",
                    },
                    {
                        "gR",
                        function()
                            lsp.execute({
                                command = "typescript.findAllFileReferences",
                                arguments = { vim.uri_from_bufnr(0) },
                                open = true,
                            })
                        end,
                        "File References",
                        has = "textDocument/references",
                    },
                    {
                        "<leader>cO",
                        function()
                            lsp["source.organizeImports"]()
                        end,
                        "Organize Imports",
                        has = "textDocument/codeAction",
                    },
                    {
                        "<leader>cM",
                        function()
                            lsp["source.addMissingImports.ts"]()
                        end,
                        "Add Missing Imports",
                        has = "textDocument/codeAction",
                    },
                    {
                        "<leader>cF",
                        function()
                            lsp["source.fixAll.ts"]()
                        end,
                        "Fix All",
                        has = "textDocument/codeAction",
                    },
                    {
                        "<leader>cV",
                        function()
                            lsp.execute({
                                command = "typescript.selectTypeScriptVersion",
                            })
                        end,
                        "Select TS workspace version",
                    },
                },
                settings = {
                    vtsls = {
                        enableMoveToFileCodeAction = true,
                        autoUseWorkspaceTsdk = true,
                        experimental = {
                            completion = {
                                enableServerSideClientsideTelemetry = false,
                            },
                        },
                        diagnostics = {
                            globallyEnabled = true,
                        },
                        tsserver = {
                            globalPlugins = {},
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
            })

            opts.servers.eslint = vim.tbl_deep_extend("force", opts.servers.eslint or {}, {
                -- Gate: jangan attach di project tanpa eslint config (mis. finnca tanpa eslint.config.mjs)
                -- Cegah "No ESLint configuration found" + hemat 1 client di mono/web Tanpa lint
                root_dir = function(bufnr, on_dir)
                    local fname = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr)
                        or bufnr
                    if fname == "" then
                        on_dir(nil)
                        return
                    end
                    local has_eslint = vim.fs.find({
                        "eslint.config.js",
                        "eslint.config.mjs",
                        "eslint.config.cjs",
                        ".eslintrc",
                        ".eslintrc.js",
                        ".eslintrc.cjs",
                        ".eslintrc.json",
                        ".eslintrc.yaml",
                        ".eslintrc.yml",
                        "package.json",
                    }, { path = fname, upward = true })[1]
                    -- package.json cek isi ada "eslintConfig" baru anggap ada
                    if has_eslint and has_eslint:match("package%.json") then
                        local ok, lines = pcall(vim.fn.readfile, has_eslint)
                        if
                            not (ok and lines and table.concat(lines, "\n"):find('"eslintConfig"'))
                        then
                            has_eslint = nil
                            -- cari lagi yang bukan package.json
                            has_eslint = vim.fs.find({
                                "eslint.config.js",
                                "eslint.config.mjs",
                                "eslint.config.cjs",
                                ".eslintrc",
                                ".eslintrc.js",
                                ".eslintrc.cjs",
                                ".eslintrc.json",
                            }, { path = fname, upward = true })[1]
                        end
                    end
                    if not has_eslint then
                        on_dir(nil)
                        return
                    end
                    local root = require("core.root").root_dir(fname, {
                        "eslint.config.js",
                        "eslint.config.mjs",
                        "eslint.config.cjs",
                        ".eslintrc",
                        ".eslintrc.js",
                        ".eslintrc.cjs",
                        ".eslintrc.json",
                        "package.json",
                        ".git",
                    })
                    on_dir(root or vim.fn.fnamemodify(fname, ":h"))
                end,
                settings = {
                    workingDirectories = { mode = "auto" },
                    format = { enable = false },
                    -- NOTE: run = "onType" dihapus karena Neovim v0.10+
                    -- menggunakan pull diagnostics — opsi ini tidak lagi
                    -- berpengaruh di sisi LSP eslint.
                    problems = { shortenToSingleLine = false },
                    codeAction = {
                        disableRuleComment = { enable = true, location = "separateLine" },
                        showDocumentation = { enable = true },
                    },
                },
            })
        end,
    },
    {
        "mfussenegger/nvim-dap",
        ft = { "typescript", "javascript", "typescriptreact", "javascriptreact", "svelte", "vue" },
        dependencies = { "nvim-neotest/nvim-nio" },
        opts = function()
            local ok, dap = pcall(require, "dap")
            if not ok then
                return
            end
            local js_filetypes = {
                "typescript",
                "javascript",
                "typescriptreact",
                "javascriptreact",
                "svelte",
                "vue",
            }

            -- JS/TS debug adapters — dipindah dari dap.lua agar hanya aktif
            -- ketika buffer JS/TS dibuka (ft-scoped plugin spec).
            if not dap.adapters["pwa-node"] then
                dap.adapters["pwa-node"] = {
                    type = "server",
                    host = "localhost",
                    port = "${port}",
                    executable = {
                        command = "js-debug-adapter",
                        args = { "${port}" },
                    },
                }
            end
            dap.adapters["node"] = dap.adapters["pwa-node"]
            dap.adapters["node-terminal"] = dap.adapters["pwa-node"]

            for _, adapterType in ipairs({ "chrome", "msedge" }) do
                local pwaType = "pwa-" .. adapterType
                if not dap.adapters[pwaType] then
                    dap.adapters[pwaType] = {
                        type = "server",
                        host = "localhost",
                        port = "${port}",
                        executable = {
                            command = "js-debug-adapter",
                            args = { "${port}" },
                        },
                    }
                end
                if not dap.adapters[adapterType] then
                    dap.adapters[adapterType] = function(cb, config)
                        config.type = pwaType
                        local native = dap.adapters[pwaType]
                        if type(native) == "function" then
                            native(cb, config)
                        else
                            cb(native)
                        end
                    end
                end
            end

            local ok_vscode, vscode = pcall(require, "dap.ext.vscode")
            if ok_vscode then
                vscode.type_to_filetypes["node"] = js_filetypes
                vscode.type_to_filetypes["pwa-node"] = js_filetypes
            end

            -- Evaluasi lazily: runtimeExecutable dipanggil saat launch, bukan saat config
            local ts_runtime = function()
                return vim.fn.executable("tsx") == 1 and "tsx" or "ts-node"
            end

            for _, language in ipairs(js_filetypes) do
                if not dap.configurations[language] then
                    local is_ts = language:find("typescript")
                    dap.configurations[language] = {
                        {
                            type = "pwa-node",
                            request = "launch",
                            name = "Launch file",
                            program = "${file}",
                            cwd = "${workspaceFolder}",
                            sourceMaps = true,
                            runtimeExecutable = is_ts and ts_runtime or nil,
                            skipFiles = { "<node_internals>/**", "node_modules/**" },
                            resolveSourceMapLocations = {
                                "${workspaceFolder}/**",
                                "!**/node_modules/**",
                            },
                        },
                        {
                            type = "pwa-node",
                            request = "attach",
                            name = "Attach",
                            processId = require("dap.utils").pick_process,
                            cwd = "${workspaceFolder}",
                            sourceMaps = true,
                            runtimeExecutable = is_ts and ts_runtime or nil,
                            skipFiles = { "<node_internals>/**", "node_modules/**" },
                            resolveSourceMapLocations = {
                                "${workspaceFolder}/**",
                                "!**/node_modules/**",
                            },
                        },
                    }
                end
            end
        end,
    },
}
