return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
        "folke/lazydev.nvim",
        "mason-org/mason-lspconfig.nvim",
        "smjonas/inc-rename.nvim",
    },

    opts = {
        servers = {
            ["*"] = {
                keys = {
                    {
                        "gd",
                        vim.lsp.buf.definition,
                        "Go to Definition",
                        has = "textDocument/definition",
                    },
                    {
                        "gD",
                        vim.lsp.buf.declaration,
                        "Go to Declaration",
                        has = "textDocument/declaration",
                    },
                    {
                        "gi",
                        vim.lsp.buf.implementation,
                        "Go to Implementation",
                        has = "textDocument/implementation",
                    },
                    {
                        "gy",
                        vim.lsp.buf.type_definition,
                        "Go to Type Definition",
                        has = "textDocument/typeDefinition",
                    },
                    { "gr", vim.lsp.buf.references, "References", has = "textDocument/references" },
                    {
                        "K",
                        function()
                            vim.lsp.buf.hover()
                        end,
                        "Hover",
                        has = "textDocument/hover",
                    },
                    {
                        "gK",
                        function()
                            vim.lsp.buf.signature_help()
                        end,
                        "Signature Help",
                        has = "textDocument/signatureHelp",
                    },
                    {
                        "<leader>cf",
                        function()
                            require("conform").format({ bufnr = 0 })
                        end,
                        "Format Buffer or Selection",
                        mode = { "n", "v" },
                    },
                    {
                        "<leader>ca",
                        vim.lsp.buf.code_action,
                        "Code Action",
                        has = "textDocument/codeAction",
                        mode = { "n", "v" },
                    },
                    {
                        "<leader>cr",
                        function()
                            return ":IncRename " .. vim.fn.expand("<cword>")
                        end,
                        "Rename Symbol",
                        expr = true,
                        has = "textDocument/rename",
                    },
                    { "<leader>cS", vim.lsp.buf.workspace_symbol, "Workspace Symbols" },
                    {
                        "<leader>cE",
                        function()
                            vim.lsp.buf.code_action({
                                context = { only = { "refactor.extract" } },
                                apply = true,
                            })
                        end,
                        "Extract (refactor)",
                        has = "textDocument/codeAction",
                    },
                    {
                        "<leader>cI",
                        function()
                            vim.lsp.buf.code_action({
                                context = { only = { "refactor.inline" } },
                                apply = true,
                            })
                        end,
                        "Inline (refactor)",
                        has = "textDocument/codeAction",
                    },
                    {
                        "<leader>cH",
                        function()
                            local buf = vim.api.nvim_get_current_buf()
                            if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
                                return
                            end
                            vim.lsp.inlay_hint.enable(
                                not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }),
                                { bufnr = buf }
                            )
                        end,
                        "Toggle Inline Hints",
                        has = "textDocument/inlayHint",
                    },
                    { "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics" },
                    {
                        "[d",
                        function()
                            vim.diagnostic.jump({ count = -1, float = true })
                        end,
                        "Prev Diagnostic",
                    },
                    {
                        "]d",
                        function()
                            vim.diagnostic.jump({ count = 1, float = true })
                        end,
                        "Next Diagnostic",
                    },
                },
            },
        },
    },

    config = function(_, opts)
        local diag_icons = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
        }
        local diag_hl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticError",
            [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
            [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticHint",
        }

        vim.diagnostic.config({
            update_in_insert = false,
            jump = { float = true },
            severity_sort = true,
            underline = { severity = { min = vim.diagnostic.severity.WARN } },
            signs = { text = diag_icons },
            virtual_text = {
                source = "if_many",
                spacing = 4,
                prefix = "●",
            },
            float = {
                source = true,
                focusable = false,
                header = { "󰀦  Diagnostics", "DiagnosticInfo" },
                prefix = function(diag)
                    return diag_icons[diag.severity] or "● ", diag_hl[diag.severity]
                end,
            },
        })

        local ok, blink = pcall(require, "blink.cmp")
        local capabilities = ok and blink.get_lsp_capabilities()
            or vim.lsp.protocol.make_client_capabilities()

        capabilities.textDocument = capabilities.textDocument or {}
        capabilities.textDocument.foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
        }

        local global_keys = (opts.servers["*"] or {}).keys or {}

        local lsp_msg_level = {
            [1] = vim.log.levels.ERROR,
            [2] = vim.log.levels.WARN,
            [3] = vim.log.levels.INFO,
            [4] = vim.log.levels.DEBUG,
        }
        local lsp_log_level = vim.tbl_extend("force", {}, lsp_msg_level, {
            [4] = vim.log.levels.TRACE,
        })

        local base_handlers = {
            ["window/showMessage"] = function(_, result, ctx)
                local client = vim.lsp.get_client_by_id(ctx.client_id)
                vim.notify(
                    result.message,
                    lsp_msg_level[result.type] or vim.log.levels.INFO,
                    { title = client and client.name or "LSP" }
                )
            end,

            ["window/logMessage"] = function(_, result, ctx)
                local level = lsp_log_level[result.type] or vim.log.levels.TRACE
                if level >= vim.log.levels.WARN then
                    local client = vim.lsp.get_client_by_id(ctx.client_id)
                    vim.notify(result.message, level, {
                        title = (client and client.name or "LSP") .. " [log]",
                    })
                end
            end,
        }

        local global_config = vim.tbl_deep_extend(
            "force",
            { capabilities = capabilities, handlers = base_handlers },
            opts.servers["*"] or {}
        )
        global_config.keys = nil
        vim.lsp.config("*", global_config)

        -- Unifikasi LspAttach: Menjamin SEMUA client LSP (termasuk rustaceanvim,
        -- clangd_extensions, dsb.) mendapatkan keymaps & behavior standar secara konsisten.
        local lsp_attach_group =
            vim.api.nvim_create_augroup("lsp_attach_universal", { clear = true })
        vim.api.nvim_create_autocmd("LspAttach", {
            group = lsp_attach_group,
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client then
                    return
                end
                local bufnr = args.buf

                -- Bind keymap global
                for _, k in ipairs(global_keys) do
                    if not k.has or client:supports_method(k.has, bufnr) then
                        local mode = k.mode or "n"
                        vim.keymap.set(mode, k[1], k[2], {
                            buffer = bufnr,
                            desc = "LSP: " .. (k[3] or k.desc or ""),
                            nowait = k.nowait,
                            silent = true,
                            noremap = true,
                            expr = k.expr,
                        })
                    end
                end

                -- Bind keymap spesifik server jika didefinisikan di opts.servers[client.name].keys
                local server_opts = opts.servers[client.name]
                if type(server_opts) == "table" and server_opts.keys then
                    for _, k in ipairs(server_opts.keys) do
                        if not k.has or client:supports_method(k.has, bufnr) then
                            local mode = k.mode or "n"
                            vim.keymap.set(mode, k[1], k[2], {
                                buffer = bufnr,
                                desc = "LSP: " .. (k[3] or k.desc or ""),
                                nowait = k.nowait,
                                silent = true,
                                noremap = true,
                                expr = k.expr,
                            })
                        end
                    end
                end

                vim.keymap.set("i", "<M-s>", function()
                    vim.lsp.buf.signature_help()
                end, {
                    buffer = bufnr,
                    desc = "LSP: Signature Help (insert)",
                    silent = true,
                    noremap = true,
                })
            end,
        })

        local have_mason, mason_lspconfig = pcall(require, "mason-lspconfig")
        local mason_all = have_mason and mason_lspconfig.get_available_servers() or {}

        local function configure(server)
            if server == "*" then
                return false
            end

            local sopts = opts.servers[server]
            sopts = sopts == true and {} or not sopts and { enabled = false } or sopts

            if sopts.enabled == false then
                return false
            end

            local autostart = sopts.autostart ~= false
            sopts.autostart = nil
            sopts.keys = nil

            local use_mason = sopts.mason ~= false and vim.tbl_contains(mason_all, server)
            -- `mason` adalah flag internal config ini, bukan opsi server LSP.
            -- Tanpa dihapus, field asing ini ikut diteruskan ke vim.lsp.config().
            sopts.mason = nil

            vim.lsp.config(server, sopts)
            if autostart then
                vim.lsp.enable(server)
            end

            return use_mason
        end

        local names = vim.tbl_keys(opts.servers)
        table.sort(names)
        local install = {}
        for _, server in ipairs(names) do
            local ok, use_mason = pcall(configure, server)
            if ok and use_mason then
                table.insert(install, server)
            elseif not ok then
                vim.notify("LSP config error for " .. server, vim.log.levels.WARN)
            end
        end

        if have_mason then
            mason_lspconfig.setup({
                ensure_installed = install,
                -- FALSE: automatic_enable=true memanggil vim.lsp.enable() untuk
                -- SEMUA package mason terpasang (features/automatic_enable.lua
                -- init()), bypass framework di file ini — termasuk vue_ls yang
                -- sengaja disabled (duplikasi vtsls+plugin di .vue) dan nama
                -- non-LSP seperti stylua. Enable dilakukan eksklusif via
                -- configure()/vim.lsp.enable di atas.
                automatic_enable = false,
            })
        end
    end,
}
