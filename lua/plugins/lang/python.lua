return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}

            -- ========================================
            -- basedpyright + ruff (python)
            -- ========================================
            opts.servers.basedpyright =
                vim.tbl_deep_extend("force", opts.servers.basedpyright or {}, {
                    root_markers = {
                        "pyproject.toml",
                        "uv.lock",
                        ".python-version",
                        "setup.py",
                        "setup.cfg",
                        "requirements.txt",
                        "Pipfile",
                        "pyrightconfig.json",
                        ".git",
                    },
                    before_init = function(_, config)
                        local function strip_funcs(t)
                            if type(t) ~= "table" then
                                return
                            end
                            for k, v in pairs(t) do
                                if type(v) == "function" then
                                    t[k] = nil
                                elseif type(v) == "table" then
                                    strip_funcs(v)
                                end
                            end
                        end
                        strip_funcs(config.settings)
                        config.settings = config.settings or {}
                        config.settings.python = config.settings.python or {}
                        config.settings.python.pythonPath = require("core.venv").get_python_path()
                    end,

                    settings = {
                        basedpyright = {
                            -- ruff yang handle organize imports (lint I) — cegah duplicate codeAction
                            disableOrganizeImports = true,
                            analysis = {
                                typeCheckingMode = "standard",
                                autoImportCompletions = true,
                                autoSearchPaths = true,
                                -- useLibraryCodeForTypes dibiarkan default (true) biar hover lib third-party tidak Unknown
                                diagnosticMode = "openFilesOnly",
                                -- Matikan background indexing agar RAM 3.4GB Celeron N4120 tidak thrashing swap
                                indexing = false,
                                inlayHints = {
                                    variableTypes = true,
                                    functionReturnTypes = true,
                                    parameterNames = "all",
                                    callArgumentNames = false,
                                },
                                diagnosticSeverityOverrides = {
                                    reportAny = "warning",
                                    reportUnknownVariableType = "warning",
                                    reportUnknownMemberType = "warning",
                                    reportUnknownParameterType = "warning",
                                    reportMissingTypeStubs = "none",
                                    reportPrivateUsage = "none",
                                    -- serahkan unused-* ke ruff (F401/F841) biar tidak duplikat diagnostic
                                    reportUnusedClass = "none",
                                    reportUnusedFunction = "none",
                                    reportUnusedVariable = "none",
                                    reportUnusedImport = "none",
                                    reportUnnecessaryTypeIgnoreComment = "warning",
                                },
                                exclude = {
                                    "**/.git",
                                    "**/__pycache__",
                                    "**/.pytest_cache",
                                    "**/.mypy_cache",
                                    "**/.ruff_cache",
                                    "**/.venv",
                                    "**/venv",
                                    "**/env",
                                    "**/build",
                                    "**/dist",
                                    "**/node_modules",
                                    "**/.uv",
                                    "**/__pypackages__",
                                    "**/.direnv",
                                },
                                ignore = { "**/migrations" },
                            },
                        },
                    },
                })

            -- ========================================
            -- ruff LSP (linter + import organizer)
            -- basedpyright = type checker (hover/completion/definition)
            -- ruff = lint/format/imports — hover & formatting dimatikan biar tidak redundan
            -- ========================================
            opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
                -- Jika ruff native sistem tersedia (pacman), jangan pasang via Mason (cegah duplikasi)
                mason = (vim.fn.executable("ruff") == 0),
                keys = {
                    {
                        "<leader>cO",
                        function()
                            vim.lsp.buf.code_action({
                                apply = true,
                                context = {
                                    only = { "source.organizeImports.ruff" },
                                    diagnostics = {},
                                },
                            })
                        end,
                        desc = "Organize Imports (ruff)",
                        has = "textDocument/codeAction",
                    },
                    {
                        "<leader>cF",
                        function()
                            vim.lsp.buf.code_action({
                                apply = true,
                                context = { only = { "source.fixAll.ruff" }, diagnostics = {} },
                            })
                        end,
                        desc = "Fix All (ruff)",
                        has = "textDocument/codeAction",
                    },
                },
                on_attach = function(client, _)
                    if client.name == "ruff" then
                        -- hover/signatureHelp milik basedpyright (Astral docs)
                        client.server_capabilities.hoverProvider = false
                        -- Formatting Python ditangani conform (ruff_organize_imports +
                        -- ruff_format). Matikan capability format dari LSP ruff agar
                        -- opsi lsp_format="fallback" di conform tidak pernah memicu
                        -- jalur format kedua.
                        client.server_capabilities.documentFormattingProvider = false
                        client.server_capabilities.documentRangeFormattingProvider = false
                    end
                end,
            })
        end,
        keys = {
            {
                "<leader>kv",
                function()
                    require("core.venv").select_venv()
                end,
                desc = "Select VirtualEnv (uv/snacks)",
                ft = "python",
            },
        },
    },
    {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        keys = {
            {
                "<leader>dPt",
                function()
                    require("dap-python").test_method()
                end,
                desc = "Debug Test Method",
                ft = "python",
            },
            {
                "<leader>dPc",
                function()
                    require("dap-python").test_class()
                end,
                desc = "Debug Test Class",
                ft = "python",
            },
        },
        config = function()
            local dap_python_ok, dap_python = pcall(require, "dap-python")
            if not dap_python_ok then
                return
            end

            -- Prioritas adapter Python: Mason debugpy venv > fallback python3 sistem
            local mason_debugpy = vim.fs.joinpath(
                vim.fn.stdpath("data"),
                "mason",
                "packages",
                "debugpy",
                "venv",
                "bin",
                "python"
            )
            local adapter_bin = (vim.uv.fs_stat(mason_debugpy) and mason_debugpy)
                or (vim.fn.exepath("python3") or "python3")

            dap_python.setup(adapter_bin)
            dap_python.test_runner = "pytest"
            dap_python.resolve_python = function()
                return require("core.venv").get_python_path()
            end
        end,
    },
}
