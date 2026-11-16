return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile", "CmdlineEnter", "VeryLazy" },
        dependencies = {
            "b0o/SchemaStore.nvim",
        },
        config = function()
            require("config.lsp").enable()
        end,
    },

    {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonLog" },
        opts_extend = { "ensure_installed" },
        init = function()
            local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
            if not (vim.env.PATH or ""):find(mason_bin, 1, true) then
                vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
            end
        end,
        opts = {
            ui = {
                border = "single",
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
            log_level = vim.log.levels.INFO,
            max_concurrent_installers = 2,
            -- Core essentials only (additional formatters/linters/DAPs installed on-demand via :Mason)
            ensure_installed = {
                "stylua",
                "shfmt",
                "prettierd",
            },
        },
        config = function(_, opts)
            require("mason").setup(opts)
            local mr = require("mason-registry")
            mr:on("package:install:success", function()
                vim.defer_fn(function()
                    require("lazy.core.handler.event").trigger({
                        event = "FileType",
                        buf = vim.api.nvim_get_current_buf(),
                    })
                end, 100)
            end)

            vim.defer_fn(function()
                for _, tool in ipairs(opts.ensure_installed or {}) do
                    pcall(function()
                        local p = mr.get_package(tool)
                        if not p:is_installed() then
                            p:install()
                        end
                    end)
                end
            end, 2000)
        end,
    },

    {
        "mason-org/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },
        opts = {
            -- Core LSP servers only; install extra language servers via :MasonInstall
            ensure_installed = {
                "lua_ls",
                "basedpyright",
            },
            -- Server activation handled natively via vim.lsp.enable() in config.lsp
            automatic_enable = false,
        },
    },

    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "snacks.nvim", words = { "Snacks" } },
                { path = "obsidian.nvim", words = { "obsidian" } },
                { path = "lazy.nvim" },
            },
            enabled = function()
                if vim.g.lazydev_enabled ~= nil then
                    return vim.g.lazydev_enabled
                end
                return true
            end,
            integrations = {
                blink_cmp = true,
            },
        },
    },

    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>uF",
                function()
                    vim.g.disable_autoformat = not vim.g.disable_autoformat
                    if vim.g.disable_autoformat then
                        vim.notify("Auto-format disabled", vim.log.levels.WARN)
                    else
                        vim.notify("Auto-format enabled", vim.log.levels.INFO)
                    end
                end,
                desc = "Toggle Auto-format",
            },
        },
        opts = {
            default_format_opts = {
                timeout_ms = 1000,
                async = true,
                quiet = false,
                lsp_format = "fallback",
            },
            formatters_by_ft = {
                javascript = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                typescript = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                javascriptreact = {
                    "biome-check",
                    "prettierd",
                    "prettier",
                    stop_after_first = true,
                },
                typescriptreact = {
                    "biome-check",
                    "prettierd",
                    "prettier",
                    stop_after_first = true,
                },
                css = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                scss = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                less = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                html = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                json = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                jsonc = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                json5 = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                svelte = { "prettierd", "prettier", stop_after_first = true },
                vue = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                astro = { "biome-check", "prettierd", "prettier", stop_after_first = true },
                yaml = { "yamlfmt", "prettierd", "prettier", stop_after_first = true },
                ["yaml.docker-compose"] = {
                    "yamlfmt",
                    "prettierd",
                    "prettier",
                    stop_after_first = true,
                },
                markdown = { "prettierd", "markdown-toc", "injected" },
                lua = { "stylua" },
                python = { "ruff_organize_imports", "ruff_format" },
                sh = { "shfmt" },
                bash = { "shfmt" },
                toml = { "taplo", lsp_format = "prefer" },
                sql = { "sqlfluff", "sql_formatter", stop_after_first = true },
                proto = { "buf", lsp_format = "prefer" },
                c = { lsp_format = "prefer" },
                cpp = { lsp_format = "prefer" },
                go = { lsp_format = "prefer" },
                rust = { "rustfmt", lsp_format = "prefer" },
                zig = { "zigfmt", lsp_format = "prefer" },
                dart = { "dart_format", lsp_format = "prefer" },
            },
            formatters = {
                ["biome-check"] = {
                    condition = function(_, ctx)
                        return vim.fs.find(
                            { "biome.json", "biome.jsonc" },
                            { path = ctx.filename, upward = true }
                        )[1] ~= nil
                    end,
                },
                ["markdown-toc"] = {
                    condition = function(_, ctx)
                        for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
                            if line:find("<!%-%- toc %-%->") then
                                return true
                            end
                        end
                    end,
                },
                injected = {
                    options = { ignore_errors = true },
                },
            },
            format_after_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
                if ok and stats and stats.size > 100 * 1024 then
                    return
                end
                if vim.bo[bufnr].buftype ~= "" then
                    return
                end
                return { timeout_ms = 1000, lsp_format = "fallback" }
            end,
            notify_on_error = true,
            notify_no_formatters = false,
            log_level = vim.log.levels.WARN,
        },
    },

    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            linters_by_ft = {
                sh = { "shellcheck" },
                bash = { "shellcheck" },
                zsh = { "shellcheck" },
                css = { "stylelint" },
                scss = { "stylelint" },
                astro = { "stylelint" },
                svelte = { "stylelint" },
                dockerfile = { "hadolint" },
                go = { "golangcilint" },
                html = { "htmlhint" },
                json = {},
                lua = { "selene" },
                markdown = { "markdownlint-cli2" },
                proto = {}, -- buf_ls LSP handles protobuf diagnostics directly
                python = {}, -- ruff LSP handles Python lint directly
                sql = { "sqlfluff" },
                systemd = { "systemdlint" },
                yaml = { "yamllint", "actionlint" },
                ["yaml.docker-compose"] = { "yamllint" },
            },
            linters = {
                actionlint = {
                    condition = function(ctx)
                        return ctx.filename:find("%.github[/\\]workflows[/\\]", 1, false) ~= nil
                    end,
                },
                selene = {
                    condition = function(ctx)
                        return vim.fs.find({ "selene.toml" }, { path = ctx.dirname, upward = true })[1]
                            ~= nil
                    end,
                },
                ["markdownlint-cli2"] = {
                    condition = function(ctx)
                        return vim.fs.find({
                            ".markdownlint-cli2.jsonc",
                            ".markdownlint-cli2.yaml",
                            ".markdownlint",
                            ".markdownlint.json",
                            ".markdownlint.jsonc",
                            ".markdownlint.yaml",
                            ".markdownlint.yml",
                            ".markdownlint.cjs",
                            ".markdownlint.mjs",
                            "markdownlint.json",
                            "markdownlint.yaml",
                            "markdownlint.yml",
                            "markdownlint.cjs",
                            "markdownlint.mjs",
                        }, { path = ctx.dirname, upward = true })[1] ~= nil
                    end,
                },
                htmlhint = {
                    condition = function(ctx)
                        return vim.fs.find({
                            ".htmlhintrc",
                            ".htmlhintrc.json",
                            ".htmlhintrc.js",
                            "htmlhint.config.js",
                        }, { path = ctx.dirname, upward = true })[1] ~= nil
                    end,
                },
                stylelint = {
                    condition = function(ctx)
                        return vim.fs.find({
                            ".stylelintrc",
                            ".stylelintrc.json",
                            ".stylelintrc.yaml",
                            ".stylelintrc.yml",
                            ".stylelintrc.js",
                            "stylelint.config.js",
                            "stylelint.config.mjs",
                        }, { path = ctx.dirname, upward = true })[1] ~= nil
                    end,
                },
                sqlfluff = {
                    condition = function(ctx)
                        return vim.fs.find({
                            ".sqlfluff",
                            ".sqlfluff.toml",
                            "pyproject.toml",
                            "setup.cfg",
                            "tox.ini",
                        }, { path = ctx.dirname, upward = true })[1] ~= nil
                    end,
                },
                golangcilint = {
                    condition = function(ctx)
                        return vim.fs.find({
                            "go.work",
                            "go.mod",
                            ".golangci.yml",
                            ".golangci.yaml",
                            ".golangci.toml",
                            ".golangci.json",
                        }, { path = ctx.dirname, upward = true })[1] ~= nil
                    end,
                },
            },
        },
        config = function(_, opts)
            local lint = require("lint")
            lint.linters_by_ft = opts.linters_by_ft
            for name, linter in pairs(opts.linters or {}) do
                lint.linters[name] = lint.linters[name] or {}
                lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
            end

            local lint_timers = {}
            local _notified_missing = {}

            local function smart_lint(bufnr, event_name)
                if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                    return
                end
                local ft = vim.bo[bufnr].filetype
                if ft == "" or vim.b[bufnr].sqlite_path then
                    return
                end

                local linters = lint.linters_by_ft[ft] or {}
                local available = {}
                for _, name in ipairs(linters) do
                    -- Heavy Go linter runs only on BufWritePost (avoids CPU spikes on InsertLeave)
                    if name == "golangcilint" and event_name ~= "BufWritePost" then
                        goto continue
                    end
                    local linter = lint.linters[name]
                    if linter then
                        local should_run = true
                        if linter.condition then
                            local filename = vim.api.nvim_buf_get_name(bufnr)
                            local dirname = filename ~= "" and vim.fn.fnamemodify(filename, ":h")
                                or vim.fn.getcwd()
                            local ctx = { dirname = dirname, filename = filename, bufnr = bufnr }
                            local ok, res = pcall(linter.condition, ctx)
                            if not ok or not res then
                                should_run = false
                            end
                        end
                        if should_run then
                            local cmd = type(linter.cmd) == "function" and linter.cmd()
                                or linter.cmd
                            if vim.fn.executable(cmd or name) == 1 then
                                table.insert(available, name)
                            elseif not _notified_missing[name] then
                                _notified_missing[name] = true
                                vim.notify(
                                    "Linter '" .. name .. "' tidak ditemukan. Install via Mason.",
                                    vim.log.levels.WARN,
                                    { title = "nvim-lint" }
                                )
                            end
                        end
                    end
                    ::continue::
                end

                if #available > 0 and vim.api.nvim_buf_is_valid(bufnr) then
                    vim.api.nvim_buf_call(bufnr, function()
                        lint.try_lint(available)
                    end)
                end
            end

            vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
                group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
                callback = function(args)
                    local bufnr = args.buf
                    local ev = args.event
                    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                        return
                    end
                    local timer = lint_timers[bufnr]
                    if timer then
                        pcall(function()
                            if not timer:is_closing() then
                                timer:stop()
                                timer:close()
                            end
                        end)
                    end
                    local new_timer = vim.uv.new_timer()
                    lint_timers[bufnr] = new_timer
                    new_timer:start(
                        300,
                        0,
                        vim.schedule_wrap(function()
                            pcall(function()
                                if not new_timer:is_closing() then
                                    new_timer:close()
                                end
                            end)
                            lint_timers[bufnr] = nil
                            smart_lint(bufnr, ev)
                        end)
                    )
                end,
            })

            vim.api.nvim_create_autocmd("BufDelete", {
                group = vim.api.nvim_create_augroup("user_lint_cleanup", { clear = true }),
                callback = function(args)
                    local timer = lint_timers[args.buf]
                    if timer then
                        pcall(function()
                            if not timer:is_closing() then
                                timer:stop()
                                timer:close()
                            end
                        end)
                        lint_timers[args.buf] = nil
                    end
                end,
            })
        end,
    },

    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        dependencies = { "echasnovski/mini.icons" },
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics" },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics",
            },
            {
                "<leader>xE",
                "<cmd>Trouble diagnostics toggle filter.severity=vim.diagnostic.severity.ERROR<cr>",
                desc = "Errors Only",
            },
            {
                "<leader>xW",
                "<cmd>Trouble diagnostics toggle filter.severity={min=vim.diagnostic.severity.WARN}<cr>",
                desc = "Warnings + Errors",
            },
            { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
            {
                "<leader>xl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Panel",
            },
            { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
            { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
        },
        opts = {
            auto_close = true,
            focus = true,
        },
    },

    {
        "smjonas/inc-rename.nvim",
        cmd = "IncRename",
        config = true,
    },

    {
        "danymat/neogen",
        cmd = "Neogen",
        keys = {
            {
                "<leader>cN",
                function()
                    require("neogen").generate()
                end,
                desc = "Generate Annotations",
            },
        },
        opts = {
            languages = {
                rust = {
                    template = { annotation_convention = "rustdoc" },
                },
            },
        },
    },

    {
        "p00f/clangd_extensions.nvim",
        ft = { "c", "cpp", "objc", "objcpp" },
        opts = {
            ast = {
                role_icons = {
                    type = "",
                    declaration = "",
                    expression = "",
                    specifier = "",
                    statement = "",
                    ["template argument"] = "",
                },
                kind_icons = {
                    Compound = "",
                    Recovery = "",
                    TranslationUnit = "",
                    PackExpansion = "",
                    TemplateTypeParm = "",
                    TemplateTemplateParm = "",
                    TemplateParamObject = "",
                },
            },
        },
    },
}
