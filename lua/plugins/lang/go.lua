return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.gopls = vim.tbl_deep_extend("force", opts.servers.gopls or {}, {
                cmd_env = {
                    GOGC = "50",
                    GOMEMLIMIT = "400MiB",
                },
                settings = {
                    gopls = {
                        gofumpt = vim.fn.executable("gofumpt") == 1,
                        ["local"] = "",
                        buildFlags = {},
                        standaloneTags = { "ignore" },
                        vulncheck = "Off",
                        diagnosticsDelay = "500ms",
                        completionBudget = "100ms",
                        symbolScope = "workspace",
                        codelenses = {
                            gc_details = false,
                            generate = true,
                            regenerate_cgo = true,
                            run_govulncheck = true,
                            test = false,
                            tidy = true,
                            upgrade_dependency = true,
                            vendor = true,
                            vulncheck = false,
                        },
                        hints = {
                            assignVariableTypes = true,
                            compositeLiteralFields = true,
                            compositeLiteralTypes = true,
                            constantValues = true,
                            functionTypeParameters = true,
                            parameterNames = true,
                            rangeVariableTypes = true,
                        },
                        analyses = {
                            fieldalignment = true,
                            nilness = true,
                            unusedparams = true,
                            unusedwrite = true,
                            useany = true,
                            modernize = true,
                            shadow = true,
                        },
                        usePlaceholders = true,
                        completeUnimported = true,
                        staticcheck = true,
                        directoryFilters = {
                            "-.git",
                            "-.vscode",
                            "-.idea",
                            "-.vscode-test",
                            "-node_modules",
                            "-dist",
                            "-build",
                        },
                        semanticTokens = true,
                    },
                },
                keys = {
                    {
                        "<leader>cO",
                        function()
                            vim.lsp.buf.code_action({
                                context = { only = { "source.organizeImports" } },
                                apply = true,
                            })
                            local clients = vim.lsp.get_clients({ name = "gopls" })
                            if clients[1] then
                                clients[1]:exec_cmd({ command = "gopls.tidy" })
                            end
                            vim.notify("go mod tidy done", vim.log.levels.INFO, { title = "Go" })
                        end,
                        "Go: Tidy imports + mod",
                        has = "textDocument/codeAction",
                    },
                    {
                        "<leader>cF",
                        function()
                            vim.lsp.buf.code_action({
                                context = { only = { "source.fixAll" } },
                                apply = true,
                            })
                        end,
                        "Go: Fix all (gopls)",
                        has = "textDocument/codeAction",
                    },
                    {
                        "<leader>kL",
                        function()
                            vim.lsp.codelens.refresh({ bufnr = 0 })
                            vim.schedule(function()
                                vim.lsp.codelens.run()
                            end)
                        end,
                        "Go: Run Code Lens",
                    },
                    {
                        "<leader>kTa",
                        function()
                            if vim.fn.executable("gomodifytags") == 0 then
                                vim.notify(
                                    "gomodifytags tidak ditemukan. Install via Mason.",
                                    vim.log.levels.ERROR,
                                    { title = "Go Tags" }
                                )
                                return
                            end
                            local file = vim.api.nvim_buf_get_name(0)
                            if file == "" then
                                vim.notify(
                                    "Buffer belum disimpan ke file",
                                    vim.log.levels.WARN,
                                    { title = "Go Tags" }
                                )
                                return
                            end
                            local tag = vim.fn.input("Tag name (default: json): ")
                            if tag == "" then
                                tag = "json"
                            end
                            local line = vim.api.nvim_win_get_cursor(0)[1]
                            vim.system({
                                "gomodifytags",
                                "-file",
                                file,
                                "-line",
                                tostring(line),
                                "-add-tags",
                                tag,
                                "-w",
                            }, { text = true }, function(out)
                                vim.schedule(function()
                                    if out.code == 0 then
                                        vim.cmd("edit!")
                                        vim.notify(
                                            "Added `" .. tag .. "` tag to struct",
                                            vim.log.levels.INFO,
                                            { title = "Go Tags" }
                                        )
                                    else
                                        vim.notify(
                                            "gomodifytags gagal:\n"
                                                .. (out.stderr ~= "" and out.stderr or out.stdout),
                                            vim.log.levels.ERROR,
                                            { title = "Go Tags" }
                                        )
                                    end
                                end)
                            end)
                        end,
                        "Go: Add struct tags",
                    },
                    {
                        "<leader>kTr",
                        function()
                            if vim.fn.executable("gomodifytags") == 0 then
                                vim.notify(
                                    "gomodifytags tidak ditemukan. Install via Mason.",
                                    vim.log.levels.ERROR,
                                    { title = "Go Tags" }
                                )
                                return
                            end
                            local file = vim.api.nvim_buf_get_name(0)
                            if file == "" then
                                vim.notify(
                                    "Buffer belum disimpan ke file",
                                    vim.log.levels.WARN,
                                    { title = "Go Tags" }
                                )
                                return
                            end
                            local tag = vim.fn.input("Tag name to remove (default: json): ")
                            if tag == "" then
                                tag = "json"
                            end
                            local line = vim.api.nvim_win_get_cursor(0)[1]
                            vim.system({
                                "gomodifytags",
                                "-file",
                                file,
                                "-line",
                                tostring(line),
                                "-remove-tags",
                                tag,
                                "-w",
                            }, { text = true }, function(out)
                                vim.schedule(function()
                                    if out.code == 0 then
                                        vim.cmd("edit!")
                                        vim.notify(
                                            "Removed `" .. tag .. "` tag from struct",
                                            vim.log.levels.INFO,
                                            { title = "Go Tags" }
                                        )
                                    else
                                        vim.notify(
                                            "gomodifytags gagal:\n"
                                                .. (out.stderr ~= "" and out.stderr or out.stdout),
                                            vim.log.levels.ERROR,
                                            { title = "Go Tags" }
                                        )
                                    end
                                end)
                            end)
                        end,
                        "Go: Remove struct tags",
                    },
                    {
                        "<leader>kG",
                        function()
                            if vim.fn.executable("gotests") == 0 then
                                vim.notify(
                                    "gotests tidak ditemukan. Install via Mason.",
                                    vim.log.levels.ERROR,
                                    { title = "Go Tests" }
                                )
                                return
                            end
                            local file = vim.api.nvim_buf_get_name(0)
                            if file == "" then
                                vim.notify(
                                    "Buffer belum disimpan ke file",
                                    vim.log.levels.WARN,
                                    { title = "Go Tests" }
                                )
                                return
                            end
                            local func = vim.fn.expand("<cword>")

                            local function run_all()
                                vim.system(
                                    { "gotests", "-w", "-all", file },
                                    { text = true },
                                    function(all_out)
                                        vim.schedule(function()
                                            if all_out.code == 0 then
                                                vim.notify(
                                                    "Generated unit tests for all functions",
                                                    vim.log.levels.INFO,
                                                    { title = "Go Tests" }
                                                )
                                            else
                                                vim.notify(
                                                    "gotests gagal:\n"
                                                        .. (
                                                            all_out.stderr ~= ""
                                                                and all_out.stderr
                                                            or all_out.stdout
                                                        ),
                                                    vim.log.levels.ERROR,
                                                    { title = "Go Tests" }
                                                )
                                            end
                                        end)
                                    end
                                )
                            end

                            vim.system(
                                { "gotests", "-w", "-only", "^" .. func .. "$", file },
                                { text = true },
                                function(out)
                                    vim.schedule(function()
                                        if out.code == 0 then
                                            vim.notify(
                                                "Generated unit tests for " .. func,
                                                vim.log.levels.INFO,
                                                { title = "Go Tests" }
                                            )
                                        else
                                            run_all()
                                        end
                                    end)
                                end
                            )
                        end,
                        "Go: Generate unit tests (gotests)",
                    },
                    {
                        "<leader>ki",
                        function()
                            if vim.fn.executable("impl") == 0 then
                                vim.notify(
                                    "impl tidak ditemukan. Install via Mason.",
                                    vim.log.levels.ERROR,
                                    { title = "Go Impl" }
                                )
                                return
                            end
                            local recv = vim.fn.input("Receiver (e.g. 'f *Foo'): ")
                            if recv == "" then
                                return
                            end
                            local iface = vim.fn.input("Interface (e.g. 'io.Reader'): ")
                            if iface == "" then
                                return
                            end
                            vim.system({ "impl", recv, iface }, { text = true }, function(out)
                                vim.schedule(function()
                                    if out.code == 0 and out.stdout ~= "" then
                                        local lines = vim.split(out.stdout, "\n", { plain = true })
                                        local row = vim.api.nvim_win_get_cursor(0)[1]
                                        vim.api.nvim_buf_set_lines(0, row, row, false, lines)
                                        vim.notify(
                                            "Implemented interface stubs",
                                            vim.log.levels.INFO,
                                            { title = "Go Impl" }
                                        )
                                    else
                                        vim.notify(
                                            "impl gagal:\n"
                                                .. (out.stderr ~= "" and out.stderr or out.stdout),
                                            vim.log.levels.ERROR,
                                            { title = "Go Impl" }
                                        )
                                    end
                                end)
                            end)
                        end,
                        "Go: Implement interface (impl)",
                    },
                },
            })
        end,
    },
    {
        "leoluz/nvim-dap-go",
        ft = "go",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        opts = {
            delve = {
                initialize_timeout_sec = 30,
            },
        },
    },
}
